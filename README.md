# TripGenie – Smart Travel Planner

## Overview

TripGenie is a Flutter-based travel planning application developed as part of the Mobile Information Systems course project. The main goal of the application is to simplify the travel planning process by combining destination discovery, weather forecasting, attraction recommendations, budget estimation and trip organization into a single platform.

Instead of manually searching for destinations, activities, weather information and travel expenses across multiple websites, users can generate a personalized travel plan by selecting a destination, travel dates, budget and personal interests. The application then creates a structured itinerary containing real locations, estimated costs and weather forecasts.

---

## Project Architecture

The application follows a layered architecture that separates user interface components, state management, business logic and external services.

The presentation layer consists of multiple Flutter screens and reusable custom widgets. State management is implemented using the Provider pattern, while all communication with external APIs is handled through dedicated service classes. User data, saved trips and favorite places are stored in Firebase Firestore.

The project is organized into:

* Screens
* Providers
* Services
* Models
* Widgets

This structure improves maintainability, scalability and code readability.

---

## Authentication and User Management

TripGenie uses Firebase Authentication to provide a complete authentication system. Users can create accounts, log in, reset passwords and manage their profiles.

Additional profile functionality includes:

* Updating username
* Updating email address
* Changing password
* Uploading profile images
* Persistent login sessions

All user-related information is synchronized with Firebase Firestore.

---

## Trip Creation

The Create Trip screen represents the core functionality of the application.

Users can:

* Search destinations using autocomplete suggestions
* Select travel dates
* Define a travel budget
* Choose interests and activity categories
* Use their current GPS location
* Preview selected locations on Google Maps

Destination suggestions are retrieved using the Open-Meteo Geocoding API, while current location functionality combines Geolocator and Google Geocoding services.

---

## Personalized Travel Planning

After entering trip details, the application automatically generates a personalized travel itinerary.

The generated plan includes:

* Morning activities
* Afternoon activities
* Evening activities
* Weather forecasts
* Attraction information
* Estimated costs
* Ratings and reviews

Locations are selected according to the user's interests, destination and budget preferences.

The system combines information from multiple APIs to create realistic travel recommendations.

---

## External APIs and Services

The application integrates several external services:

### Firebase

* Authentication
* Firestore Database
* Cloud Messaging
* Storage

### Google APIs

* Google Maps API
* Google Places API
* Google Geocoding API

### Open-Meteo API

* City search
* Weather forecasts

### Ticketmaster API

* Event discovery
* Ticket price estimation

---

## Data Management

All user data is stored in Firebase Firestore.

The database contains:

* User profiles
* Saved trips
* Favorite places
* Notification tokens

Each user has their own isolated data structure, ensuring secure storage and personalized content.

---

## Camera and Media Support

TripGenie allows users to upload profile images from both the gallery and camera.

For mobile devices, image selection is implemented using ImagePicker. For web devices, a dedicated WebCameraScreen accesses the browser camera directly and captures profile photos.

Uploaded images are stored in Firebase Storage and automatically linked to the user's profile.

---

## Notifications

Push notifications are implemented using Firebase Cloud Messaging and Flutter Local Notifications.

The application stores FCM tokens for each user and supports both remote and local notifications.

This functionality can be used for future travel reminders, updates and trip-related alerts.

---

## User Interface

The application features a modern interface inspired by popular travel platforms such as Booking and Airbnb.

Key design characteristics include:

* Responsive layouts
* Gradient-based design
* Dark mode support
* Custom reusable widgets
* Glassmorphism-inspired cards
* Consistent visual styling

Custom widgets such as GradientActionButton, GlassCard, AppInputCard, SectionTitle and TripStatCard are reused throughout the application to ensure a unified user experience.

---

## Technologies Used

* Flutter
* Dart
* Firebase Authentication
* Cloud Firestore
* Firebase Storage
* Firebase Cloud Messaging
* Provider
* Google Maps API
* Google Places API
* Google Geocoding API
* Open-Meteo API
* Ticketmaster API

---

## Conclusion

TripGenie successfully combines Flutter, Firebase and multiple third-party APIs into a complete travel planning solution. The project demonstrates state management, authentication, location services, camera integration, cloud storage, external API consumption and modern UI design within a single application.

The system provides users with a convenient way to organize trips while generating personalized travel plans based on their preferences, budget and destination.
