<!DOCTYPE html>
<html <?php language_attributes(); ?>>
<head>
    <meta charset="<?php bloginfo('charset'); ?>">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title><?php wp_title('|', true, 'right'); ?><?php bloginfo('name'); ?></title>
    <?php wp_head(); ?>
</head>
<body <?php body_class(); ?>>

<header class="site-header">
    <div class="header-content">
        <div class="site-branding">
            <h1 class="site-title">
                <a href="<?php echo esc_url(home_url('/')); ?>"><?php bloginfo('name'); ?></a>
            </h1>
            <?php 
            $description = get_bloginfo('description', 'display');
            if ($description || is_customize_preview()) : ?>
                <p class="site-description"><?php echo $description; ?></p>
            <?php endif; ?>
        </div>
    </div>
    
    <nav class="main-navigation">
        <ul class="nav-menu">
            <li><a href="<?php echo esc_url(home_url('/')); ?>">Home</a></li>
            <li><a href="<?php echo esc_url(home_url('/about-us')); ?>">About Us</a></li>
            <li><a href="<?php echo esc_url(home_url('/services')); ?>">Services</a></li>
            <li><a href="<?php echo esc_url(home_url('/contact')); ?>">Contact</a></li>
        </ul>
    </nav>
</header>