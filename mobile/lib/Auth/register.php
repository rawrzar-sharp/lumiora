<?php
session_start();
// Attempt to load the PDO instance from possible config locations
// Primary expected location (relative to this file)
require_once __DIR__ . '/../config/db.php';
// If db.php didn't provide $pdo, try one directory up (project root style)
if (!isset($pdo) || !$pdo) {
    $alt = __DIR__ . '/../../config/db.php';
    if (file_exists($alt)) {
        require_once $alt;
    }
}

// If still not set, throw a clear error
if (!isset($pdo) || !$pdo) {
    die('Database connection not found. Ensure config/db.php defines $pdo.');
}

if ($_SERVER["REQUEST_METHOD"] == "POST") {
    $name = $_POST['name'];
    $contact_info = $_POST['contact_info']; // Can be email or phone
    $password = password_hash($_POST['password'], PASSWORD_DEFAULT);
    
    // Insert into Lumiora's customers table
    $stmt = $pdo->prepare("INSERT INTO `customers` (name, contact_info, password, loyalty_stamps, vouchers) VALUES (?, ?, ?, 0, 0)");
    
    try {
        $stmt->execute([$name, $contact_info, $password]);
        header("Location: login.php?registered=1");
        exit();
    } catch (PDOException $e) {
        $error = "Registration failed. Contact Info might already be in use.";
    }
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Lumiora - Register</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <style>
        body, html {
            height: 100%; margin: 0;
            background-color: #EBE5D9;
            font-family: 'Sans-Serif', Arial, sans-serif;
        }
        .register-card {
            background: #FBF8F1;
            border-radius: 24px;
            width: 100%; max-width: 500px;
            padding: 3rem; margin: 40px auto;
            border: 2px solid #7B8C2A;
            box-shadow: 0px 8px 25px rgba(0, 0, 0, 0.1);
        }
        .brand-title {
            color: #B59A57; font-family: 'serif'; font-size: 32px; font-weight: bold; text-align: center; letter-spacing: 2px;
        }
        .form-control {
            border: 1px solid #DCE2B9; border-radius: 12px; height: 50px; margin-bottom: 1rem;
        }
        .form-control:focus { border-color: #7B8C2A; box-shadow: 0 0 0 3px rgba(123, 140, 42, 0.2); }
        .lbl-input { font-size: 14px; font-weight: 600; color: #2C3028; margin-bottom: 5px; display: block; }
        .btn-register {
            background-color: #7B8C2A; color: white; border-radius: 12px; font-weight: bold; height: 50px; border: none; width: 100%; margin-top: 1rem;
        }
        .btn-register:hover { background-color: #5E6D1F; }
        .link-text { color: #7B8C2A; text-decoration: none; display: block; text-align: center; margin-top: 1rem; font-weight: 600; }
    </style>
</head>
<body>
<div class="container d-flex align-items-center min-vh-100">
    <div class="register-card">
        <div class="brand-title mb-4">LUMIORÀ</div>
        <h5 class="text-center mb-4" style="color: #4A4D4A;">Join Lumiora Rewards</h5>
        
        <?php if (isset($error)): ?>
            <div class="alert alert-danger"><?= $error ?></div>
        <?php endif; ?>

        <form method="POST">
            <div>
                <label class="lbl-input">Full Name</label>
                <input type="text" name="name" class="form-control" placeholder="Enter your name" required>
            </div>
            <div>
                <label class="lbl-input">Email or Phone Number</label>
                <input type="text" name="contact_info" class="form-control" placeholder="Enter email or phone" required>
            </div>
            <div>
                <label class="lbl-input">Password</label>
                <input type="password" name="password" class="form-control mb-2" placeholder="Create a password" required>
            </div>
            <button type="submit" class="btn-register">BECOME A MEMBER</button>
            <a href="login.php" class="link-text">Already have an account? Sign In</a>
        </form>
    </div>
</div>
</body>
</html>