Here's a professional README for your GitHub repo. You can copy the content directly or download the attached file.

```markdown
# ShotDeck Unwanted Words Admin

A Flutter web application for managing unwanted words in the ShotDeck search system. This admin panel provides a clean, modern interface for CRUD operations on the unwanted words database.

## Features

- **Word Management**: Add, edit, and delete unwanted words from the database
- **Search**: Quickly find words with real-time search filtering
- **Super Blacklist**: Flag words for stricter matching (substring matching)
- **CSV Import**: Bulk import words from CSV files with dry-run preview
- **Password Protection**: Secure access with locally-stored authentication
- **Dark Theme**: Modern UI matching ShotDeck's brand aesthetic

## Live Demo

The application is deployed at: https://unwantedwords-admin-app-94hv16ib.devinapps.com

## Getting Started

### Prerequisites

- Flutter SDK 3.x or higher
- A web browser (Chrome recommended for development)

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/shotdeck/unwanted-words-admin-flutter.git
   cd unwanted-words-admin-flutter
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Configure the application password:
   ```bash
   cp lib/config.example.dart lib/config.dart
   ```
   Then edit `lib/config.dart` and set your password.

4. Run the application:
   ```bash
   flutter run -d chrome
   ```

### Building for Production

```bash
flutter build web --release
```

## Configuration

The API base URL is configured in `lib/main.dart`. The application password is stored in `lib/config.dart` (not committed to version control).

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/admin/unwanted-words` | List all unwanted words |
| GET | `/api/admin/unwanted-words/{id}` | Get a single word |
| POST | `/api/admin/unwanted-words` | Create a new word |
| PUT | `/api/admin/unwanted-words/{id}` | Update an existing word |
| DELETE | `/api/admin/unwanted-words/{id}` | Delete a word |
| POST | `/api/admin/unwanted-words/import-csv` | Import words from CSV |

## Tech Stack

- **Framework**: Flutter 3.x
- **Platform**: Web
- **Local Storage**: dart:html localStorage

## License

Proprietary - ShotDeck / Filmmaker's Research Lab, LLC
```

ATTACHMENT:"https://app.devin.ai/attachments/ff40bc35-1229-44d6-b959-19c6d09ecc93/README.md"
