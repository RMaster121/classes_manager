# Class Manager App - Development Instructions

## Overview
This document provides instructions for creating a class management application using Flutter. The app is designed for tutors and teachers to manage their private classes, track schedules, and handle student information.

## Core Features
1. Class Management
   - Schedule one-time and recurring classes
   - Track class duration and pricing
   - Mark classes as completed or cancelled
   - View past and upcoming classes
   - Edit individual or future recurring classes

2. Student Management
   - Store student information
   - Assign unique colors to students for easy identification
   - Track student-specific classes

3. Subject Management
   - Define different subjects
   - Set base price per hour for each subject

## Data Models

### Class Model
```dart
class Class {
  final String id;
  final Student student;
  final Subject subject;
  final DateTime dateTime;
  final double duration;
  final ClassStatus status;
  final ClassType type;
  final String? notes;
}

enum ClassStatus { planned, completed, cancelled }
enum ClassType { oneTime, recurring }
```

### Student Model
```dart
class Student {
  final String id;
  final String name;
  final Color color;
}
```

### Subject Model
```dart
class Subject {
  final String id;
  final String name;
  final double basePricePerHour;
}
```

## UI Components

### Main Screen (Classes Screen)
1. Display classes in a scrollable list
2. Show class cards with:
   - Student avatar with first letter
   - Student name
   - Date and time
   - Subject
   - Price
   - Recurring indicator (if applicable)
3. Implement pull-to-refresh for loading past classes
4. Add FloatingActionButton for creating new classes

### Class Card Design
1. Use Card widget with ListTile
2. Include:
   - Leading: CircleAvatar with student initial
   - Title: Student name
   - Subtitle: Date, time, and price
   - Trailing: More options menu
3. Visual features:
   - Fade past/completed classes
   - Show recurring indicator for recurring classes
   - Display price with proper currency formatting

### Add/Edit Class Dialog
1. Form fields for:
   - Student selection (dropdown)
   - Subject selection (dropdown)
   - Date picker
   - Time picker
   - Duration slider (0.5 to 3.0 hours)
   - Class type selection (one-time/recurring)
   - Notes field
2. For recurring classes:
   - Week selection dropdown
   - Option to edit future occurrences

## Implementation Guidelines

### Database Service
1. Implement methods for:
   - Adding classes
   - Updating classes
   - Marking classes as completed
   - Cancelling classes
   - Fetching classes for specific time periods
   - Managing recurring classes

### Localization
1. Support multiple languages
2. Format dates according to locale
3. Use proper currency symbols (e.g., "zł" for Polish, "$" for English)
4. Implement proper text capitalization for different languages

### UI/UX Best Practices
1. Use proper spacing and padding
2. Implement visual feedback for user actions
3. Show loading indicators during data operations
4. Provide error handling and user feedback
5. Maintain consistent visual hierarchy
6. Use appropriate typography scales

### Performance Considerations
1. Implement pagination for large datasets
2. Optimize list rendering
3. Handle background data loading
4. Manage state efficiently

## Code Organization
1. Separate screens into different files
2. Create reusable widgets
3. Implement proper state management
4. Use constants for repeated values
5. Follow clean architecture principles

## Testing Guidelines
1. Write unit tests for business logic
2. Implement widget tests for UI components
3. Test edge cases in date/time handling
4. Verify localization works correctly
5. Test data persistence

## Security Considerations
1. Implement proper data validation
2. Secure storage of sensitive information
3. Handle authentication if required
4. Validate user inputs

## Future Enhancements
1. Payment tracking
2. Student attendance history
3. Revenue reports
4. Calendar integration
5. Notifications for upcoming classes
6. Export functionality for reports

## Development Process
1. Set up Flutter development environment
2. Create necessary data models
3. Implement database service
4. Build UI components
5. Add localization support
6. Implement business logic
7. Test thoroughly
8. Deploy to app stores

Remember to follow Flutter best practices and maintain clean, documented code throughout the development process.


