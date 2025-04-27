<?php
/**
 * The file that defines the core plugin class
 *
 * @since      1.0.0
 *
 * @package    Github\login
 */

namespace LWG\Auth;

use Exception;
use LWG\Auth\LoginOption;
use League\OAuth2\Client\Provider\Github;

if ( ! class_exists( 'LoginWithGitHub' ) ) {
	/**
	 * The core plugin class.
	 */
	class LoginWithGitHub {

		/**
		 * Github client ID.
		 *
		 * @var string $client_id
		 */
		private $client_id;

		/**
		 * Github secret key.
		 *
		 * @var string $secret_key
		 */
		private $secret_key;

		/**
		 * Github redirect url.
		 *
		 * @var string $redirect_url
		 */
		private $redirect_url;

		/**
		 * New register enable.
		 *
		 * @var bool $register_enable
		 */
		private $register_enable;

		/**
		 * Github auth url.
		 *
		 * @var string $auth_url
		 */
		private $auth_url;

		/**
		 * Class constructor.
		 */
		public function __construct() {
			$github_login          = new LoginOption();
			$this->client_id       = $github_login->get_option( 'client_id' );
			$this->secret_key      = $github_login->get_option( 'client_secret' );
			$this->redirect_url    = $github_login->get_option( 'redirect_url' );
			$this->register_enable = $github_login->get_option( 'registration_enabled' );

			add_action( 'wp_enqueue_scripts', array( $this, 'lwg_auth_enqueue_scipts' ) );
			add_action( 'login_enqueue_scripts', array( $this, 'lwg_auth_enqueue_scipts' ) );
			add_action( 'init', array( $this, 'lwg_auth_register_shortcode' ) );
			add_action( 'init', array( $this, 'lwg_auth_login_with_github' ) );
			add_action( 'init', array( $this, 'lwg_auth_add_login_shortcode' ) );
		}

		/**
		 * Enqueue scripts.
		 */
		public function lwg_auth_enqueue_scipts() {
			wp_register_style( 'bootstrap-css', LWG_AUTH_ABSURL . 'assets/css/bootstrap.min.css', array(), LWG_AUTH_ABSURL, 'all' );
			wp_register_script( 'bootstrap-js', LWG_AUTH_ABSURL . 'assets/js/bootstrap.bundle.min.js', array(), LWG_AUTH_ABSURL, true );

			wp_enqueue_style( 'bootstrap-css' );
			wp_enqueue_script( 'bootstrap-js' );
		}

		/**
		 * Register new shortcode for login with Github button.
		 */
		public function lwg_auth_register_shortcode() {
			add_shortcode( 'lwg_auth_button', array( $this, 'lwg_auth_button' ) );
		}

		/**
		 * Login with Github button.
		 *
		 * @return string The content for the GitHub login button.
		 */
		public function lwg_auth_button() {
			$content = '';
			if ( ! $this->client_id || ! $this->secret_key || ! $this->redirect_url ) {
				return $content;
			}
			$this->auth_url = $this->lwg_auth_get_provider()->getAuthorizationUrl();
			$content        = '<div class="text-center my-3">';
			$content       .= sprintf(
				'<a href="%s" class="btn btn-lg d-flex align-items-center justify-content-center mx-auto border border-dark" style="max-width: 300px;">' .
				'<img src="' . LWG_AUTH_ABSURL . 'assets/images/github.svg" />' . // phpcs:ignore PluginCheck.CodeAnalysis.ImageFunctions.NonEnqueuedImage
				'<i class="bi bi-github me-2" aria-hidden="true"></i>%s</a>',
				esc_url( $this->auth_url ),
				esc_html__( 'Login with GitHub', 'login-with-github' )
			);
			$content       .= '</div>';
			return $content;
		}

		/**
		 * Login with github.
		 */
		public function lwg_auth_login_with_github() {
			if ( ! isset( $_GET['code'] ) ) { // phpcs:ignore WordPress.Security.NonceVerification.Recommended
				return '';
			}
			// phpcs:ignore WordPress.Security.NonceVerification.Recommended
			$code = sanitize_text_field( wp_unslash( $_GET['code'] ) );
			try {
				$provider     = $this->lwg_auth_get_provider();
				$access_token = $provider->getAccessToken(
					'authorization_code',
					array(
						'code' => $code,
					)
				);
				$user         = $provider->getResourceOwner( $access_token );
				$github_user  = $user->toArray();
				$email        = isset( $github_user['email'] ) ? $github_user['email'] : '';
				if ( $email ) {
					$userinfo = get_user_by( 'email', $email );
					if ( $userinfo ) {
						wp_set_current_user( $userinfo->ID, $userinfo->user_login );
						wp_set_auth_cookie( $userinfo->ID );
						wp_safe_redirect( site_url() );
						exit;
					} elseif ( $this->register_enable ) {
						$role    = apply_filters( 'lwg_auth_login_user_role', 'subscriber' );
						$user_id = wp_insert_user(
							array(
								'user_login' => $github_user['login'],
								'user_email' => $email,
								'user_pass'  => '',
								'role'       => $role,
							)
						);

						if ( $user_id ) {
							wp_set_current_user( $user_id );
							wp_set_auth_cookie( $user_id );
							wp_safe_redirect( site_url() );
							exit;
						}
					} else {
						wp_die( 'User is not exists' );
					}
				}
			} catch ( Exception $e ) {
				wp_die( 'Authentication failed', 'Error', array( 'response' => 500 ) );
			}
		}

		/**
		 * Get GitHub provider.
		 */
		private function lwg_auth_get_provider() {
			return new Github(
				array(
					'clientId'     => $this->client_id,
					'clientSecret' => $this->secret_key,
					'redirectUri'  => $this->redirect_url,
				)
			);
		}

		/**
		 * Initialize login button shortcode into forms.
		 */
		public function lwg_auth_add_login_shortcode() {
			add_action( 'login_form', array( $this, 'lwg_auth_do_shortcode' ) );
		}

		/**
		 * Add shortcode.
		 */
		public function lwg_auth_do_shortcode() {
			echo do_shortcode( '[lwg_auth_button]' );
		}
	}
}
