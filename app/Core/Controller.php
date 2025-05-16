<?php
namespace App\Core;

use Exception;

class Controller
{
    /**
     * Render a view
     */
    protected function view(string $name, array $data = [])
    {
        extract($data);

        $viewPath = "../app/Views/{$name}.php";

        if (!file_exists($viewPath)) {
            throw new Exception("View {$name} not found");
        }

        ob_start();
        require $viewPath;
        $content = ob_get_clean();

        // Check if layout exists
        $layoutPath = "../app/Views/layouts/main.php";
        if (file_exists($layoutPath)) {
            require $layoutPath;
        } else {
            echo $content;
        }
    }

    /**     * Return JSON response
     */
    protected function json(array $data, int $statusCode = 200)
    {
        header('Content-Type: application/json');
        http_response_code($statusCode);
        echo json_encode($data);
        exit;
    }

    /**
     * Render a view as JSON response
     */
    protected function viewAsJson(string $name, array $data = [], int $statusCode = 200)
    {
        header('Content-Type: application/json');
        http_response_code($statusCode);

        // Extract data to make it available in the view
        extract($data);

        // Capture the output from the view
        ob_start();
        $viewPath = "../app/Views/{$name}.php";

        if (!file_exists($viewPath)) {
            throw new Exception("View {$name} not found");
        }

        require $viewPath;
        $output = ob_get_clean();

        // Output the result directly since the view might contain JSON
        echo $output;
        exit;
    }    /**
         * Redirect to another URL
         * 
         * @param string $url The URL to redirect to
         * @param array $flashData Optional flash data to store in session
         * @return void
         */
    protected function redirect(string $url, array $flashData = [])
    {
        // Store any flash data in the session
        foreach ($flashData as $key => $value) {
            $_SESSION[$key] = $value;
        }

        header("Location: {$url}");
        exit;
    }
}