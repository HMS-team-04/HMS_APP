# HMS Service Test Views

This folder contains test views for testing the functionality of each service in the HMS app. These views are designed to help developers verify that the services are working correctly and understand how to use them.

## Available Test Views

### 1. TestAdminView
- Tests the `AdminFirestoreService` functionality
- Features:
  - Create a new admin
  - Get admin details by user ID
  - Update the admin's last active time
  - Delete an admin
- Demonstrates proper usage of `Admin` model and async/await operations

### 2. TestDoctorView
- Tests the `DoctorService` functionality
- Features:
  - Add a new doctor
  - Fetch all doctors
  - Display doctor details
- Demonstrates proper creation and display of `Doctor` model

### 3. TestPatientView
- Tests the `PatientDetails` service (from FetchService.swift)
- Features:
  - Add a new patient
  - Fetch all patients
  - Display patient details
- Demonstrates working with dates and optional fields

### 4. TestStaffView
- Tests the `StaffService` functionality
- Features:
  - Add new staff with certificates
  - Upload certificate files to Firebase Storage
  - Fetch staff members
  - Display staff details
- Demonstrates complex operations like file uploads

### 5. TestDashboardView
- Provides navigation to all test views
- Acts as the main entry point for testing

## How to Use

1. Run the HMS app
2. On the main screen, tap the "Open Service Test Dashboard" button
3. Select the service you want to test
4. Use the form fields to enter data
5. Click the action buttons to perform operations
6. View results and status messages

## Important Notes

- All services connect to the Firebase Firestore database
- The database prefix is "hms4_" (for collections like "hms4_doctors", "hms4_patients", etc.)
- Test views automatically initialize Firebase if it's not already configured
- Status indicators show operation progress and results
- After adding an item, the forms will clear and refresh the data list

## Debugging

If you encounter issues:
1. Check the console logs for detailed error messages
2. Verify your Firebase Firestore rules allow read/write operations
3. Ensure the models match the expected database structure
4. Check that all required fields are provided when creating new records

These test views are independent from the main app functionality and are intended for development and testing purposes only. 