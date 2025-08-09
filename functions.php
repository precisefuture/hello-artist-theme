<?php
/**
 * Hello Artist Theme Functions
 * 
 * Child theme of Hello Elementor for eCommerce art gallery.
 * Component-based architecture without page builders.
 * 
 * @package HelloArtist
 * @since 0.1.0
 */

// Prevent direct access
if (!defined('ABSPATH')) {
    exit;
}

/**
 * Theme setup
 */
function hello_artist_setup() {
    // Add theme support for WooCommerce
    add_theme_support('woocommerce');
    
    // Add theme support for WC product gallery features
    add_theme_support('wc-product-gallery-zoom');
    add_theme_support('wc-product-gallery-lightbox');
    add_theme_support('wc-product-gallery-slider');
    
    // Add theme support for HTML5
    add_theme_support('html5', [
        'search-form',
        'comment-form',
        'comment-list',
        'gallery',
        'caption',
    ]);
    
    // Add theme support for title tag
    add_theme_support('title-tag');
}
add_action('after_setup_theme', 'hello_artist_setup');

/**
 * Enqueue parent theme styles
 */
function hello_artist_enqueue_parent_styles() {
    wp_enqueue_style(
        'hello-elementor-style',
        get_template_directory_uri() . '/style.css',
        [],
        wp_get_theme()->get('Version')
    );
}
add_action('wp_enqueue_scripts', 'hello_artist_enqueue_parent_styles');

/**
 * Theme version for cache busting
 */
function hello_artist_get_version() {
    return wp_get_theme()->get('Version');
}

/**
 * Component loader helper
 * 
 * @param string $component_name
 * @param array $args
 */
function hello_artist_load_component($component_name, $args = []) {
    $component_path = get_stylesheet_directory() . '/components/' . $component_name . '/' . $component_name . '.php';
    
    if (file_exists($component_path)) {
        // Extract args to variables
        if (!empty($args)) {
            extract($args);
        }
        include $component_path;
    }
}

/**
 * Enqueue component styles and scripts
 * 
 * @param string $component_name
 * @param array $dependencies
 */
function hello_artist_enqueue_component($component_name, $dependencies = []) {
    $version = hello_artist_get_version();
    $component_dir = get_stylesheet_directory_uri() . '/components/' . $component_name . '/';
    $component_path = get_stylesheet_directory() . '/components/' . $component_name . '/';
    
    // Enqueue CSS if exists
    if (file_exists($component_path . $component_name . '.css')) {
        wp_enqueue_style(
            'hello-artist-' . $component_name,
            $component_dir . $component_name . '.css',
            [],
            $version
        );
    }
    
    // Enqueue JS if exists
    if (file_exists($component_path . $component_name . '.js')) {
        wp_enqueue_script(
            'hello-artist-' . $component_name,
            $component_dir . $component_name . '.js',
            $dependencies,
            $version,
            true // Load in footer with defer
        );
    }
}