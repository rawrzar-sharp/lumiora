<?php
session_start();
require __DIR__ . '/../../config/db.php';

if ($_SERVER["REQUEST_METHOD"] == "POST" && isset($_POST['login'])) {
    $contact_info = $_POST['contact_info'];
    $password = $_POST['password'];
    
    // Check credentials in Lumiora customers table
    $user = false;
    if (isset($pdo) && $pdo instanceof PDO) {
        $stmt = $pdo->prepare("SELECT * FROM `customers` WHERE contact_info = ?");
        $stmt->execute([$contact_info]);
        $user = $stmt->fetch(PDO::FETCH_ASSOC);
    } elseif (isset($conn) && $conn instanceof mysqli) {
        $stmt = $conn->prepare("SELECT id, name, contact_info, password, loyalty_stamps FROM `customers` WHERE contact_info = ?");
        $stmt->bind_param('s', $contact_info);
        $stmt->execute();
        $res = $stmt->get_result();
        $user = $res->fetch_assoc();
    } else {
        // Attempt to detect common variable names from included config
        if (isset($db) && $db instanceof PDO) {
            $pdo = $db;
            $stmt = $pdo->prepare("SELECT * FROM `customers` WHERE contact_info = ?");
            $stmt->execute([$contact_info]);
            $user = $stmt->fetch(PDO::FETCH_ASSOC);
        }
    }

    if ($user && password_verify($password, $user['password'])) {
        $_SESSION['user_id'] = $user['id'];
        $_SESSION['name'] = $user['name'];
        $_SESSION['contact_info'] = $user['contact_info'];
        $_SESSION['loyalty_stamps'] = $user['loyalty_stamps'];
        
        // Redirect to wherever your web dashboard is
        header("Location: ../pages/dashboard.php");
        exit();
    } else {
        $error = "Invalid Email/Phone or Password!";
    }
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Lumiora - Login</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <style>
        body, html { height: 100%; margin: 0; background-color: #EBE5D9; font-family: 'Sans-Serif', Arial, sans-serif; }
        .login-card {
            background: #FBF8F1; border-radius: 24px; width: 100%; max-width: 450px;
            padding: 40px; margin: auto; border: 2px solid #7B8C2A;
            box-shadow: 0 10px 30px rgba(0, 0, 0, 0.1);
        }
        .brand-title { color: #B59A57; font-family: 'serif'; font-size: 32px; font-weight: bold; text-align: center; letter-spacing: 2px; margin-bottom: 30px; }
        .form-control { background-color: #ffffff; border: 1px solid #DCE2B9; border-radius: 12px; padding: 12px 15px; margin-bottom: 20px; }
        .form-control:focus { border-color: #7B8C2A; box-shadow: 0 0 0 3px rgba(123, 140, 42, 0.2); }
        .lbl-input { font-weight: 600; font-size: 14px; color: #2C3028; margin-bottom: 6px; display: block; }
        .btn-login { background-color: #7B8C2A; color: #ffffff; border: none; border-radius: 12px; padding: 12px; font-weight: bold; font-size: 16px; width: 100%; }
        .btn-login:hover { background-color: #5E6D1F; }
        .bottom-links-row { display: flex; justify-content: space-between; margin-top: 20px; font-size: 14px; }
        .bottom-links-row a { color: #7B8C2A; font-weight: 600; text-decoration: none; }
    </style>
</head>
<body class="d-flex align-items-center">
<div class="container">
    <div class="login-card">
        <div class="brand-title">LUMIORÀ</div>
        
        <?php if (isset($_GET['registered'])): ?>
            <div class="alert alert-success text-center">Registration successful! Please login.</div>
        <?php endif; ?>

        <?php if (isset($error)): ?>
            <div class="alert alert-danger py-2 text-center"><?= $error ?></div>
        <?php endif; ?>

        <form method="POST" action="">
            <div>
                <label class="lbl-input">Email or Phone Number</label>
                <input type="text" name="contact_info" class="form-control" placeholder="Enter your contact info" required>
            </div>
            <div>
                <label class="lbl-input">Password</label>
                <input type="password" name="password" class="form-control" placeholder="Enter your password" required>
            </div>
            <button type="submit" name="login" class="btn-login">ACCESS ACCOUNT</button>

            <div class="bottom-links-row">
                <a href="register.php">Join Now</a>
                <a href="forgot_password.php">Forgot password?</a>
            </div>
        </form>
    </div>
</div>
</body>
</html>