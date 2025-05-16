<?php
namespace App\Core;

class Input
{
  /**
   * Get a value from GET request
   * 
   * @param string|null $key The key to look for in GET array
   * @param mixed $default Default value if key not found
   * @return mixed The value or default
   */
  public static function get(?string $key = null, mixed $default = null): mixed
  {
    if ($key === null) {
      return $_GET;
    }

    return $_GET[$key] ?? $default;
  }

  /**
   * Get a value from POST request
   * 
   * @param string|null $key The key to look for in POST array
   * @param mixed $default Default value if key not found
   * @return mixed The value or default
   */
  public static function post(?string $key = null, mixed $default = null): mixed
  {
    if ($key === null) {
      return $_POST;
    }

    return $_POST[$key] ?? $default;
  }

  /**
   * Get a value from either GET or POST
   * 
   * @param string $key The key to look for
   * @param mixed $default Default value if key not found
   * @return mixed The value or default
   */
  public static function any(string $key, mixed $default = null): mixed
  {
    return self::get($key, self::post($key, $default));
  }

  /**
   * Check if the request is AJAX
   * 
   * @return bool True if AJAX request
   */
  public static function isAjax(): bool
  {
    return !empty($_SERVER['HTTP_X_REQUESTED_WITH']) &&
      strtolower($_SERVER['HTTP_X_REQUESTED_WITH']) === 'xmlhttprequest';
  }

  /**
   * Get request method
   * 
   * @return string HTTP method (GET, POST, etc.)
   */
  public static function method(): string
  {
    return $_SERVER['REQUEST_METHOD'];
  }

  /**
   * Sanitize input
   * 
   * @param mixed $input Input to sanitize
   * @return mixed Sanitized input
   */
  public static function sanitize(mixed $input): mixed
  {
    if (is_array($input)) {
      return array_map([self::class, 'sanitize'], $input);
    }

    return htmlspecialchars((string) $input, ENT_QUOTES, 'UTF-8');
  }
}