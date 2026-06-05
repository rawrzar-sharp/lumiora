<?php
session_start();

// Attempt to include DB config from likely locations and ensure $pdo is available
$db_included = false;
$paths = [
    __DIR__ . '/../../config/db.php', // mobile/config/db.php
    __DIR__ . '/../config/db.php',    // mobile/lib/config/db.php
];
foreach ($paths as $p) {
    if (file_exists($p)) {
        require_once $p;
        $db_included = true;
        break;
    }
}

if (!$db_included || !isset($pdo)) {
    die("Database connection could not be established.");
}

if ($_SERVER["REQUEST_METHOD"] == "POST") {
    $contact_info = trim($_POST['contact_info']);
    
    // Verify if the contact info exists in Lumiora DB
    $stmt = $pdo->prepare("SELECT id, name FROM `customers` WHERE contact_info = ?");
    $stmt->execute([$contact_info]);
    $user = $stmt->fetch();

    if ($user) {
        $new_password = substr(str_shuffle("0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"), 0, 8);
        $hashed_password = password_hash($new_password, PASSWORD_DEFAULT);
        
        $update_stmt = $pdo->prepare("UPDATE `customers` SET password = ? WHERE id = ?");
        $update_stmt->execute([$hashed_password, $user['id']]);
        
        $success = "Password reset successfully. Your new temporary password is: <br><strong style='font-size: 24px; color: #7B8C2A;'>" . $new_password . "</strong><br>Please log in and change it immediately.";
    } else {
        $error = "We could not find any account associated with that email/phone.";
    }
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Lumiora - Forgot Password</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <style>
        body, html { height: 100%; margin: 0; background-color: #EBE5D9; font-family: 'Sans-Serif', Arial, sans-serif; }
        .reset-card {
            background: #FBF8F1; border-radius: 24px; width: 100%; max-width: 500px;
            padding: 3rem; margin: auto; border: 2px solid #7B8C2A;
            box-shadow: 0px 4px 20px rgba(0, 0, 0, 0.1);
        }
        .brand-title { color: #B59A57; font-family: 'serif'; font-size: 32px; font-weight: bold; text-align: center; margin-bottom: 20px; letter-spacing: 2px;}
        .form-control { border: 1px solid #DCE2B9; border-radius: 12px; height: 50px; margin-bottom: 1.5rem; }
        .form-control:focus { border-color: #7B8C2A; box-shadow: 0 0 0 3px rgba(123, 140, 42, 0.2); }
        .lbl-input { font-size: 14px; font-weight: 600; margin-bottom: 0.5rem; display: block; color: #2C3028; }
        .btn-submit { background-color: #7B8C2A; color: white; border-radius: 12px; font-size: 16px; font-weight: bold; height: 50px; border: none; width: 100%; margin-top: 1rem; }
        .btn-submit:hover { background-color: #5E6D1F; }
        .link-text { font-size: 14px; color: #7B8C2A; text-decoration: none; font-weight: 600; }
    </style>
</head>
<body class="d-flex align-items-center">
<div class="container">
    <div class="reset-card">
        <div class="brand-title">LUMIORÀ</div>
        <h5 class="text-center mb-3" style="color: #4A4D4A;">Password Recovery</h5>
        <p class="text-center text-muted mb-4">Enter your registered email or phone number to receive a temporary password.</p>

        <?php if (isset($error)): ?>
            <div class="alert alert-danger py-2"><?= $error ?></div>
        <?php endif; ?>
        
        <?php if (isset($success)): ?>
            <div class="alert alert-success py-3 text-center"><?= $success ?></div>
        <?php else: ?>
            <form method="POST">
                <div>
                    <label class="lbl-input">Email or Phone Number</label>
                    <input type="text" name="contact_info" class="form-control" placeholder="Enter your contact info" required>
                </div>
                <button type="submit" class="btn-submit">RESET PASSWORD</button>
            </form>
        <?php endif; ?>

        <div class="text-center mt-4">
            <a href="login.php" class="link-text">&#8592; Back to Sign In</a>
        </div>
    </div>
</div>
</body>
</html>