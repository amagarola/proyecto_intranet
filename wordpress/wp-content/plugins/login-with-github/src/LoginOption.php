<?php
/**
 * The file that manages the setting options.
 *
 * @since      1.0.0
 *
 * @package    Github\Login
 */

namespace LWG\Auth;

if ( ! class_exists( 'LoginOption' ) ) {
	/**
	 * Login Options Class.
	 */
	class LoginOption {

		/**
		 * Global options.
		 *
		 * @var array $options
		 */
		public $options;

		/**
		 * Setting group.
		 *
		 * @var string $option_group
		 */
		private $option_group = 'lwg_auth_settings';

		/**
		 * Option section.
		 *
		 * @var string $option_section
		 */
		private $option_section = 'lwg_auth_section';

		/**
		 * Option name.
		 *
		 * @var string $option_name
		 */
		private $option_name = 'lwg_auth_options';

		/**
		 * Setting fields.
		 *
		 * @var array $fields
		 */
		private $fields = array();

		/**
		 * Class constructor.
		 */
		public function __construct() {
			$this->options = get_option( $this->option_name, array() );

			add_action( 'init', array( $this, 'set_fields' ) );
			add_action( 'admin_menu', array( $this, 'register_settings' ) );
			add_action( 'admin_init', array( $this, 'initialize_settings' ) );
		}

		/**
		 * Set fields.
		 */
		public function set_fields() {
			$this->fields = array(
				'client_id'            => array(
					'title' => esc_html__( 'Client ID', 'login-with-github' ),
					'desc'  => sprintf(
						// Translators: %s to developer setting url.
						__( 'Enter the <a href="%s" target="_blank">Client ID</a> from your GitHub app.', 'login-with-github' ),
						'https://github.com/settings/developers'
					),
					'type'  => 'text',
					'value' => $this->get_option( 'client_id' ),
				),
				'client_secret'        => array(
					'title' => esc_html__( 'Client Secret', 'login-with-github' ),
					'desc'  => sprintf(
						// Translators: %s to developer setting url.
						__( 'Enter the <a href="%s" target="_blank">Client Secret</a> from your GitHub app.', 'login-with-github' ),
						'https://github.com/settings/developers'
					),
					'type'  => 'password',
					'value' => $this->get_option( 'client_secret' ),
				),
				'redirect_url'         => array(
					'title' => esc_html__( 'Redirect URL', 'login-with-github' ),
					'desc'  => sprintf(
						// Translators: %s to developer setting url.
						__( 'Enter the <a href="%s" target="_blank">Redirect Link</a> from your GitHub app.', 'login-with-github' ),
						'https://github.com/settings/developers'
					),
					'type'  => 'url',
					'value' => $this->get_option( 'redirect_url' ),
				),
				'registration_enabled' => array(
					'title' => esc_html__( 'Create New User', 'login-with-github' ),
					'desc'  => sprintf(
						__( 'If this setting is checked, a new user will be created even if membership setting is off.', 'login-with-github' )
					),
					'type'  => 'checkbox',
					'value' => '1',
				),
			);
		}

		/**
		 * Register settings page in the WordPress admin under "Settings".
		 */
		public function register_settings() {
			add_submenu_page(
				'options-general.php',
				esc_html__( 'Login With GitHub', 'login-with-github' ),
				esc_html__( 'Login With GitHub', 'login-with-github' ),
				'manage_options',
				'github-login-settings',
				array( $this, 'view_admin_settings' )
			);
		}

		/**
		 * Initialize settings.
		 */
		public function initialize_settings() {
			register_setting( $this->option_group, $this->option_name, array( $this, 'sanitize_settings' ) );

			add_settings_section(
				$this->option_section,
				esc_html__( 'GitHub Login Settings', 'login-with-github' ),
				null,
				$this->option_group
			);

			foreach ( $this->fields as $key => $field ) {
				add_settings_field(
					$key,
					$field['title'],
					array( $this, 'settings_field_input' ),
					$this->option_group,
					$this->option_section,
					array_merge( $field, array( 'id' => $key ) )
				);
			}
		}

		/**
		 * Sanitize setting field value.
		 *
		 * @param array $args Setting fields value.
		 */
		public function sanitize_settings( $args ) {
			return array_map( 'sanitize_text_field', $args );
		}

		/**
		 * Setting option input fields.
		 *
		 * @param array $args The arguments.
		 */
		public function settings_field_input( $args ) {
			$value = esc_attr( $args['value'] );
			$type  = $args['type'];
			$id    = esc_attr( $args['id'] );
			$desc  = $args['desc'];

			printf(
				'<input type="%s" id="%s" name="%s[%s]" value="%s"' . esc_attr( 'checkbox' === $type && $this->get_option( 'registration_enabled' ) ? 'checked="checked"' : '' ) . ' />',
				esc_attr( $type ),
				esc_attr( $id ),
				esc_attr( $this->option_name ),
				esc_attr( $id ),
				esc_attr( $value )
			);

			if ( 'checkbox' === $type ) {
				echo '<span>Create a new user account if it does not exist already</span>';
			}
			if ( $desc ) {
				echo '<p class="description">' . wp_kses_post( $desc ) . ' </p>';
			}
		}

		/**
		 * Render the admin settings page.
		 */
		public function view_admin_settings() {
			?>
			<div class="wrap">
				<h1><?php echo esc_html__( 'Login With GitHub Settings', 'login-with-github' ); ?></h1>
				<form method="post" action="options.php">
					<?php
					settings_fields( $this->option_group );
					do_settings_sections( $this->option_group );
					submit_button( esc_html__( 'Save Changes', 'login-with-github' ) );
					?>
				</form>
			</div>
			<?php
		}

		/**
		 * Get option by key name.
		 *
		 * @param string $key_name Key name.
		 * @return mixed
		 */
		public function get_option( $key_name ) {
			return isset( $this->options[ $key_name ] ) ? $this->options[ $key_name ] : '';
		}
	}
}
