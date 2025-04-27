=== Login with GitHub ===
Contributors: parthvataliya
Tags: GitHub login, sign in, sso, oauth, authentication
Requires at least: 5.5
Tested up to: 6.7
Requires PHP: 7.4
Stable tag: 1.0.3
License: GPLv2 or later
License URI: http://www.gnu.org/licenses/gpl-2.0.html

Minimal plugin that allows WordPress users to log in using GitHub.

== Description ==

Ultra minimal plugin to let your users login to WordPress applications using their GitHub accounts. No more remembering hefty passwords!

### Initial Setup

1. Create a project from [GitHub Developer Settings](https://github.com/settings/developers) if none exists.


2. Go to **OAuth** tab, then create credential for OAuth client.
    * Add `YOUR_WEBSITE_NAME` in **Application Name**
    * Add `YOUR_DOMAIN/HOME_URL` in **Homepage URL**
    * Add `YOUR_DOMAIN/wp-login.php` in **Authorized redirect URIs**


3. This will give you **Client ID** and **Secret key**.


4. Input these values either in `WP Admin > Settings > Login With GitHub`

### How to enable automatic user registration

You can enable user registration by
- Enabling *Settings > Login With GitHub > Enable GitHub Login Registration*

**Note:** If the checkbox is ON then, it will register valid GitHub users even when WordPress default setting, under

*Settings > General Settings > Membership > Anyone can register* checkbox

is OFF.

== Installation ==

1. Copy the `login-with-github` folder into your `wp-content/plugins` folder.
2. Activate the Login With GitHub plugin via the plugins admin page.
3. Install and activate the plugin.
4. Go to Settings → Login With GitHub to login or register to user
6. Add shortcode **lwg_auth_button** to login or registration file.

== Screenshots ==

1. Login screen with Google option added.
2. Plugin settings screen.
3. Settings within Google Developer Console.

== Changelog ==

= 1.0.3 =
* Add shortcode to wp-login from.

= 1.0.2 =
* Improve performance.

= 1.0.1 =
* Sanitize setting fields.

= 1.0.0 =
* Initial Release.