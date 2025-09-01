# word_game_app_puzzle

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Secret management

This app uses [flutter_dotenv](https://pub.dev/packages/flutter_dotenv) for
configuration values. Secrets are **not** checked into version control or
bundled with the application.

1. Create a `.env` file locally with the required keys (see `.env.example`).
2. Run the app with build‑time injection so the values are available to
   `flutter_dotenv`:

   ```bash
   flutter run --dart-define-from-file=.env
   ```

The `.env` file is ignored by Git and omitted from the Flutter asset bundle.
In production, provide the same keys through a secure backend or CI/CD pipeline
using `--dart-define` so the values remain private.