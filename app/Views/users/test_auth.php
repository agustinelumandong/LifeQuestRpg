<?php
// Test Auth functionality
use App\Core\Auth;

$userIsLoggedIn = Auth::check();
$currentUser = Auth::user();
$isAdmin = Auth::isAdmin();

echo '<h1>Auth Test</h1>';
echo '<pre>';
echo 'Is logged in: ' . ($userIsLoggedIn ? 'Yes' : 'No') . "\n";
echo 'Current user: ';
var_dump($currentUser);
echo 'Is admin: ' . ($isAdmin ? 'Yes' : 'No') . "\n";
echo '</pre>';
?>