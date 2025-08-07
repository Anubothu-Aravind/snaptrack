import cv2
import numpy as np
import mediapipe as mp
from fastapi import FastAPI, HTTPException
from fastapi.responses import StreamingResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import threading
import time
import asyncio
from typing import Optional
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="Driver Safety Detection API", version="1.0.0")

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize MediaPipe
mp_face_mesh = mp.solutions.face_mesh
mp_drawing = mp.solutions.drawing_utils
mp_drawing_styles = mp.solutions.drawing_styles

# Global variables
detection_active = False
camera_feed = None
current_alert = None
detection_thread = None
frame_buffer = None
drowsiness_threshold = 0.7
speed_threshold = 60.0

# Pydantic models
class CameraConfig(BaseModel):
    camera_url: str
    camera_type: str

class ThresholdConfig(BaseModel):
    drowsiness_threshold: float
    speed_threshold: float

class AlertResponse(BaseModel):
    has_alert: bool
    alert: Optional[dict] = None

# Detection classes
class DrowsinessDetector:
    def __init__(self, threshold=0.7):
        self.threshold = threshold
        self.face_mesh = mp_face_mesh.FaceMesh(
            max_num_faces=1,
            refine_landmarks=True,
            min_detection_confidence=0.5,
            min_tracking_confidence=0.5
        )
        self.consecutive_frames = 0
        self.drowsy_frames_threshold = 10
        
        # Eye landmarks indices
        self.LEFT_EYE = [362, 382, 381, 380, 374, 373, 390, 249, 263, 466, 388, 387, 386, 385, 384, 398]
        self.RIGHT_EYE = [33, 7, 163, 144, 145, 153, 154, 155, 133, 173, 157, 158, 159, 160, 161, 246]

    def calculate_ear(self, landmarks, eye_indices):
        """Calculate Eye Aspect Ratio"""
        eye_points = []
        for idx in eye_indices:
            x = landmarks[idx].x
            y = landmarks[idx].y
            eye_points.append([x, y])
        
        eye_points = np.array(eye_points)
        
        # Vertical distances
        A = np.linalg.norm(eye_points[1] - eye_points[5])
        B = np.linalg.norm(eye_points[2] - eye_points[4])
        
        # Horizontal distance
        C = np.linalg.norm(eye_points[0] - eye_points[3])
        
        # EAR calculation
        ear = (A + B) / (2.0 * C)
        return ear

    def detect_drowsiness(self, frame):
        """Detect drowsiness from frame"""
        rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        results = self.face_mesh.process(rgb_frame)
        
        if results.multi_face_landmarks:
            for face_landmarks in results.multi_face_landmarks:
                # Calculate EAR for both eyes
                left_ear = self.calculate_ear(face_landmarks.landmark, self.LEFT_EYE)
                right_ear = self.calculate_ear(face_landmarks.landmark, self.RIGHT_EYE)
                
                # Average EAR
                avg_ear = (left_ear + right_ear) / 2.0
                
                # Check if eyes are closed
                if avg_ear < self.threshold:
                    self.consecutive_frames += 1
                else:
                    self.consecutive_frames = 0
                
                # Alert if drowsy for consecutive frames
                if self.consecutive_frames >= self.drowsy_frames_threshold:
                    confidence = 1.0 - avg_ear  # Higher confidence for lower EAR
                    return {
                        'type': 'drowsiness',
                        'message': 'Driver appears to be drowsy - eyes closed detected',
                        'confidence': min(confidence, 1.0),
                        'ear_value': avg_ear
                    }
        
        return None

class SpeedDetector:
    def __init__(self, threshold=60.0):
        self.threshold = threshold
        self.prev_frame = None
        self.prev_time = None
        self.feature_detector = cv2.ORB_create()
        self.matcher = cv2.BFMatcher(cv2.NORM_HAMMING, crossCheck=True)
        
    def estimate_speed(self, frame):
        """Estimate speed using optical flow"""
        current_time = time.time()
        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        
        if self.prev_frame is not None and self.prev_time is not None:
            # Detect features in both frames
            kp1, des1 = self.feature_detector.detectAndCompute(self.prev_frame, None)
            kp2, des2 = self.feature_detector.detectAndCompute(gray, None)
            
            if des1 is not None and des2 is not None and len(des1) > 10 and len(des2) > 10:
                # Match features
                matches = self.matcher.match(des1, des2)
                matches = sorted(matches, key=lambda x: x.distance)
                
                if len(matches) > 20:
                    # Calculate displacement
                    displacements = []
                    for match in matches[:20]:  # Use top 20 matches
                        pt1 = kp1[match.queryIdx].pt
                        pt2 = kp2[match.trainIdx].pt
                        displacement = np.sqrt((pt2[0] - pt1[0])**2 + (pt2[1] - pt1[1])**2)
                        displacements.append(displacement)
                    
                    avg_displacement = np.mean(displacements)
                    time_diff = current_time - self.prev_time
                    
                    # Simple speed estimation (pixels per second to km/h conversion)
                    # This is a rough estimation and would need calibration in real scenarios
                    estimated_speed = (avg_displacement / time_diff) * 0.1  # Rough conversion factor
                    
                    if estimated_speed > self.threshold:
                        confidence = min(estimated_speed / (self.threshold * 1.5), 1.0)
                        return {
                            'type': 'speed',
                            'message': f'Vehicle speed exceeds limit: {estimated_speed:.1f} km/h',
                            'confidence': confidence,
                            'speed': estimated_speed
                        }
        
        self.prev_frame = gray.copy()
        self.prev_time = current_time
        return None

# Initialize detectors
drowsiness_detector = DrowsinessDetector(drowsiness_threshold)
speed_detector = SpeedDetector(speed_threshold)

def detection_worker():
    """Main detection worker thread"""
    global detection_active, camera_feed, current_alert, frame_buffer
    
    logger.info("Detection worker started")
    
    while detection_active:
        try:
            if camera_feed is not None:
                ret, frame = camera_feed.read()
                if ret:
                    # Store frame for streaming
                    frame_buffer = frame.copy()
                    
                    # Run drowsiness detection
                    drowsy_result = drowsiness_detector.detect_drowsiness(frame)
                    if drowsy_result:
                        current_alert = drowsy_result
                        logger.info(f"Drowsiness detected: {drowsy_result}")
                    
                    # Run speed detection
                    speed_result = speed_detector.estimate_speed(frame)
                    if speed_result:
                        current_alert = speed_result
                        logger.info(f"Speed violation detected: {speed_result}")
                
                time.sleep(0.1)  # Process at 10 FPS
            else:
                time.sleep(0.5)
                
        except Exception as e:
            logger.error(f"Error in detection worker: {e}")
            time.sleep(1)
    
    logger.info("Detection worker stopped")

def generate_frames():
    """Generate frames for video streaming"""
    global frame_buffer
    
    while detection_active:
        if frame_buffer is not None:
            # Encode frame as JPEG
            ret, buffer = cv2.imencode('.jpg', frame_buffer)
            if ret:
                frame_bytes = buffer.tobytes()
                yield (b'--frame\r\n'
                       b'Content-Type: image/jpeg\r\n\r\n' + frame_bytes + b'\r\n')
        time.sleep(0.033)  # ~30 FPS

@app.get("/")
async def root():
    return {"message": "Driver Safety Detection API", "status": "running"}

@app.get("/health")
async def health_check():
    return {"status": "healthy", "detection_active": detection_active}

@app.post("/start_detection")
async def start_detection(config: CameraConfig):
    global detection_active, camera_feed, detection_thread, drowsiness_detector, speed_detector
    
    try:
        if detection_active:
            return {"message": "Detection already active"}
        
        # Initialize camera
        if config.camera_type == "phone":
            camera_feed = cv2.VideoCapture(0)  # Default camera
        else:
            camera_feed = cv2.VideoCapture(config.camera_url)  # IP camera
        
        if not camera_feed.isOpened():
            raise HTTPException(status_code=400, detail="Failed to open camera")
        
        # Reset detectors
        drowsiness_detector = DrowsinessDetector(drowsiness_threshold)
        speed_detector = SpeedDetector(speed_threshold)
        
        # Start detection
        detection_active = True
        detection_thread = threading.Thread(target=detection_worker)
        detection_thread.start()
        
        logger.info(f"Detection started with {config.camera_type} camera")
        return {"message": "Detection started successfully"}
        
    except Exception as e:
        logger.error(f"Error starting detection: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/stop_detection")
async def stop_detection():
    global detection_active, camera_feed, detection_thread, current_alert
    
    try:
        detection_active = False
        current_alert = None
        
        if detection_thread:
            detection_thread.join(timeout=5)
        
        if camera_feed:
            camera_feed.release()
            camera_feed = None
        
        logger.info("Detection stopped")
        return {"message": "Detection stopped successfully"}
        
    except Exception as e:
        logger.error(f"Error stopping detection: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/status")
async def get_status():
    return {
        "detection_active": detection_active,
        "camera_connected": camera_feed is not None and camera_feed.isOpened() if camera_feed else False,
        "drowsiness_threshold": drowsiness_threshold,
        "speed_threshold": speed_threshold
    }

@app.get("/alerts")
async def get_alerts():
    global current_alert
    
    if current_alert:
        alert_data = current_alert.copy()
        current_alert = None  # Clear after reading
        return AlertResponse(has_alert=True, alert=alert_data)
    
    return AlertResponse(has_alert=False)

@app.post("/update_thresholds")
async def update_thresholds(config: ThresholdConfig):
    global drowsiness_threshold, speed_threshold, drowsiness_detector, speed_detector
    
    try:
        drowsiness_threshold = config.drowsiness_threshold
        speed_threshold = config.speed_threshold
        
        # Update detector thresholds
        if drowsiness_detector:
            drowsiness_detector.threshold = drowsiness_threshold
        if speed_detector:
            speed_detector.threshold = speed_threshold
            
        logger.info(f"Thresholds updated: drowsiness={drowsiness_threshold}, speed={speed_threshold}")
        return {"message": "Thresholds updated successfully"}
        
    except Exception as e:
        logger.error(f"Error updating thresholds: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/video_feed")
async def video_feed():
    """Stream video feed"""
    if not detection_active:
        raise HTTPException(status_code=400, detail="Detection not active")
    
    return StreamingResponse(
        generate_frames(),
        media_type="multipart/x-mixed-replace; boundary=frame"
    )

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)