# Classes Manager App Requirements

## Core Features
- Weekly class schedule management
- Student management
- Subject management
- Financial tracking
- Class history
- Outlook calendar integration
- Data export (Excel/CSV)
- Local backup/restore

## Data Models


### Subject
- Name
- Base price per hour
- Icon

### Student
- Name
- Assigned color
- List of subjects
- Location
- List of classes

### Class
- Student (one per class)
- Subject
- DateTime
- Duration (default: 1 hour)
- Price (default: subject's base price)
- Status (planned/cancelled/completed)
- Notes
- Type (recurring/one-time)

## Pages

### Main Page
- Weekly class list (sorted by proximity)
- Weekly total earnings
- Add buttons (class/student/subject)
- Top bar with logo and menu

### Class Details
- Class information
- Notes section
- Price details
- Status management
- Time editing
- Cancel option

### History
- All classes list
- Filters: student/subject/status
- Sorting: newest first

### Finance
- Monthly earnings
- Weekly earnings
- Total earnings

## Technical Specifications

### Platform Requirements
- Android: version 11+
- iOS: version 14+

### UI/UX
- Material Design
- Light theme (default)
- Dark theme option
- Google Fonts
- Material/Flutter icons

### Data
- Local database storage
- Single-user system
- Backup/restore capability

### Business Rules
- Schedule limit: 2 weeks ahead


