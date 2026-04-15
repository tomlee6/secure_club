enum Environment { dev, staging, prod }

class ApiConstants {
  static Environment currentEnvironment = Environment.dev;

  static String get baseUrl {
    switch (currentEnvironment) {
      case Environment.dev:
        // return 'https://tf3afdzdqk.execute-api.ap-southeast-2.amazonaws.com/dev';
        return 'https://tf3afdzdqk.execute-api.ap-southeast-2.amazonaws.com/dev';
        // return 'http://localhost:3000';
      case Environment.staging:
        return 'https://tf3afdzdqk.execute-api.ap-southeast-2.amazonaws.com/dev'; // Placeholder
      case Environment.prod:
        return 'https://tf3afdzdqk.execute-api.ap-southeast-2.amazonaws.com/dev'; // Placeholder
    }
  }
}
