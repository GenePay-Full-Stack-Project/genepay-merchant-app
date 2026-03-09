# Biometric Service Integration

## Overview
This document describes how the BioPay Merchant app integrates with the Biometric Service for face enrollment.

## Files Created/Modified

### 1. API Configuration (`lib/config/api_config.dart`)
Centralized configuration for all API endpoints:
- **Payment Service**: `http://192.168.1.4:8080`
- **Biometric Service**: `http://192.168.1.4:8001`

### 2. Biometric Service (`lib/services/biometric_service.dart`)
Service class that handles all biometric API calls:

#### Methods:
- `enrollFace()` - Enrolls a customer's face and returns face_id
- `verifyFace()` - Verifies a face during payment authentication
- `checkHealth()` - Health check for biometric service

#### Response Models:
- `EnrollFaceResponse` - Contains face_id, liveness results, quality score
- `VerifyFaceResponse` - Contains verification result, confidence scores
- `BiometricException` - Custom exception for biometric errors

### 3. Updated Enrollment Screen (`lib/screens/face_enrollment/enroll_customer_face_screen.dart`)
Enhanced the face enrollment flow:

#### Changes:
1. Added BiometricService instance
2. Captures face image from camera
3. Converts image to base64
4. Shows processing dialog during API call
5. Calls biometric service `/biometric/enroll` endpoint
6. Displays success/error messages with quality metrics
7. Navigates to QR screen with real face_id from backend

#### User Flow:
```
1. User opens enrollment screen
2. Camera initializes (front camera)
3. User positions face in guide overlay
4. User taps "Capture Face" button
5. Image is captured and converted to base64
6. Processing dialog shows "Processing face enrollment..."
7. API call to biometric service
8. Backend performs:
   - Face detection
   - Liveness detection
   - Quality checks
   - Stores face encoding
   - Returns face_id
9. Success message shows quality score and liveness status
10. Navigate to QR screen with face_id
```

### 4. QR Screen (`lib/screens/qr/face_enrollment_qr_screen.dart`)
Receives real face_id from backend and embeds it in QR code.

## API Endpoint Details

### Enroll Face
**Endpoint**: `POST /biometric/enroll`

**Request**:
```json
{
  "image_base64": "base64_encoded_image_string",
  "merchant_id": "MR-2024-001"
}
```

**Response**:
```json
{
  "success": true,
  "message": "Face enrolled successfully. Generate QR code with this face_id for customer to scan.",
  "face_id": "507f1f77bcf86cd799439011",
  "liveness_passed": true,
  "liveness_confidence": 0.95,
  "quality_score": 87.5,
  "image_url": null
}
```

### Error Handling
The service handles various error scenarios:
- Network errors
- Camera permission denied
- Face not detected
- Liveness check failed
- Poor image quality
- Backend service unavailable

Error messages are displayed in user-friendly SnackBars with retry options.

## QR Code Data Format

The QR code contains the following JSON structure:
```json
{
  "type": "face_enrollment",
  "faceId": "507f1f77bcf86cd799439011",
  "merchantId": "MR-2024-001",
  "sessionToken": "1700000000000",
  "timestamp": "2025-11-22T10:30:00.000Z"
}
```

## Customer Linking Flow

1. **Merchant** enrolls customer face → Gets face_id
2. **Merchant** shows QR code with face_id
3. **Customer** scans QR code in BioPay Client app
4. **Client app** calls Payment Service to link face_id to user_id
5. **Payment Service** calls Biometric Service `/biometric/update-face-user`
6. Face enrollment is now linked to customer account

## Configuration

Before running, update the IP addresses in `lib/config/api_config.dart`:

```dart
class ApiConfig {
  // Update these to match your backend servers
  static const String paymentServiceBaseUrl = 'http://YOUR_IP:8080';
  static const String biometricServiceBaseUrl = 'http://YOUR_IP:8001';
}
```

## Testing Checklist

- [ ] Camera permission granted
- [ ] Front camera initializes correctly
- [ ] Face guide overlay displays
- [ ] Image capture works
- [ ] Processing dialog shows during API call
- [ ] Success message displays with quality metrics
- [ ] Error handling works (network error, no face detected, etc.)
- [ ] QR code displays with correct face_id
- [ ] QR data includes all required fields

## Future Enhancements

1. **Merchant Authentication**: Get actual merchant_id from auth session
2. **Retry Logic**: Automatic retry on network failures
3. **Offline Support**: Queue enrollments when offline
4. **Image Preview**: Show captured image before sending
5. **Multiple Face Detection**: Handle cases with multiple faces in frame
6. **Image Optimization**: Compress image before sending to reduce payload

## Dependencies

Make sure these are in your `pubspec.yaml`:
```yaml
dependencies:
  camera: ^0.10.5+5
  permission_handler: ^11.0.1
  http: ^1.1.0
  qr_flutter: ^4.1.0
```
