<?php
// Enqueue styles
function simple_business_styles() {
    wp_enqueue_style('simple-business-style', get_stylesheet_uri());
}
add_action('wp_enqueue_scripts', 'simple_business_styles');

// Theme support
function simple_business_setup() {
    // Add theme support for post thumbnails
    add_theme_support('post-thumbnails');
    
    // Add theme support for title tag
    add_theme_support('title-tag');
    
    // Add theme support for custom logo
    add_theme_support('custom-logo');
    
    // Register navigation menu
    register_nav_menus(array(
        'primary' => 'Primary Menu',
    ));
}
add_action('after_setup_theme', 'simple_business_setup');

// Customize excerpt length
function simple_business_excerpt_length($length) {
    return 30;
}
add_filter('excerpt_length', 'simple_business_excerpt_length');
?>