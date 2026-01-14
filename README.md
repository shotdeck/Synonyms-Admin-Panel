# ShotDeck Keywords Admin

A Flutter web application for managing synonyms in the ShotDeck search system. This admin panel provides a clean, modern interface for CRUD operations on the synonyms database, which uses a two-table structure with master terms and their associated synonyms.

## Features

- **Master Term Management**: Add, edit, and delete master terms from the database
- **Synonym Management**: Add, edit, and delete synonyms linked to each master term
- **Expandable View**: Master terms expand to show all associated synonyms
- **Search**: Quickly find master terms and synonyms with real-time search filtering
- **Include/Exclude Toggle**: Control whether terms are included in search processing
- **CSV Import**: Bulk import master terms and synonyms from CSV files with dry-run preview
- **Password Protection**: Secure access with locally-stored authentication
- **Dark Theme**: Modern UI matching ShotDeck's brand aesthetic

## Live Demo

The application is deployed at: https://synonyms-admin-app-b3hw6g0g.devinapps.com

## Database Structure

The synonyms system uses two linked tables:

- **frl_keywords_synonyms_master**: Contains master terms (id, master_term, is_included)
- **frl_keywords_synonyms**: Contains synonyms linked to master terms via master_id (id, master_id, synonym_term, is_included)

## Getting Started

### Prerequisites

- Flutter SDK 3.x or higher
- A web browser (Chrome recommended for development)

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/shotdeck/Synonyms-Admin-Panel.git
   cd Synonyms-Admin-Panel
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Configure the application password:
   ```bash
   cp lib/config.example.dart lib/config.dart
   ```
   Then edit `lib/config.dart` and set your password (use the same password as the Unwanted Words Admin Panel).

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

### Master Terms

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/admin/synonyms/masters` | List all master terms |
| GET | `/api/admin/synonyms/masters/{id}` | Get a single master term |
| POST | `/api/admin/synonyms/masters` | Create a new master term |
| PUT | `/api/admin/synonyms/masters/{id}` | Update an existing master term |
| DELETE | `/api/admin/synonyms/masters/{id}` | Delete a master term |

### Synonyms

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/admin/synonyms/masters/{masterId}/synonyms` | List all synonyms for a master term |
| GET | `/api/admin/synonyms/synonyms/{id}` | Get a single synonym |
| POST | `/api/admin/synonyms/masters/{masterId}/synonyms` | Create a new synonym |
| PUT | `/api/admin/synonyms/synonyms/{id}` | Update an existing synonym |
| DELETE | `/api/admin/synonyms/synonyms/{id}` | Delete a synonym |

### Import

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/admin/synonyms/import-csv` | Import master terms and synonyms from CSV |

## Tech Stack

- **Framework**: Flutter 3.x
- **Platform**: Web
- **Local Storage**: dart:html localStorage

## License

Proprietary - ShotDeck / Filmmaker's Research Lab, LLC
