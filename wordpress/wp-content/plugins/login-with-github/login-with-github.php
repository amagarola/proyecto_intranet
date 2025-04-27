<?php
/**
 * Plugin Name: Login with GitHub
 * Description: Allow users to login/register via Github.
 * Version: 1.0.3
 * Author: Parth Vataliya
 * Author URI: https://profiles.wordpress.org/parthvataliya/
 * Text Domain: login-with-github
 * Domain Path: /languages
 * License: GPLv2 or later
 * License URI: http://www.gnu.org/licenses/gpl-2.0.html
 *
 * @package Github\login
 * @since 1.0.0
 */

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

define( 'LWG_AUTH_BASEFILE', __FILE__ );
define( 'LWG_AUTH_VERSION', '1.0.0' );
define( 'LWG_AUTH_ABSURL', plugins_url( '/', LWG_AUTH_BASEFILE ) );

$vendor_file = __DIR__ . '/vendor/autoload.php';
if ( is_readable( $vendor_file ) ) {
	require_once $vendor_file;
}

if ( ! function_exists( 'lwg_auth_activation' ) ) {
	/**
	 * Plugin activation.
	 */
	function lwg_auth_activation() {
	}
}
register_activation_hook( __FILE__, 'lwg_auth_activation' );

if ( ! function_exists( 'lwg_auth_deactivation' ) ) {
	/**
	 * Plugin deactivation.
	 */
	function lwg_auth_deactivation() {
	}
}
register_deactivation_hook( __FILE__, 'lwg_auth_deactivation' );

if ( ! function_exists( 'lwg_auth_init' ) ) {
	/**
	 * Initialization class.
	 */
	function lwg_auth_init() {
		new \LWG\Auth\LoginWithGitHub();
	}
}
add_action( 'plugins_loaded', 'lwg_auth_init' );
