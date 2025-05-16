<?php
/**
 * Common helper functions for views
 */

if (!function_exists('site_url')) {
  /**
   * Get site URL
   * 
   * @param string $path
   * @return string
   */
  function site_url(string $path = ''): string
  {
    $baseUrl = isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? 'https://' : 'http://';
    $baseUrl .= $_SERVER['HTTP_HOST'];

    if (!empty($path)) {
      $path = '/' . ltrim($path, '/');
    }

    return $baseUrl . $path;
  }
}

if (!function_exists('asset_url')) {
  /**
   * Get asset URL
   * 
   * @param string $path
   * @return string
   */
  function asset_url(string $path = ''): string
  {
    return site_url('assets/' . ltrim($path, '/'));
  }
}
