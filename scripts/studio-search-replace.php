<?php
/**
 * Serialisation-aware URL replacement for WordPress Studio (SQLite) sites.
 *
 * `wp search-replace` finds each table's primary key with DESCRIBE. On Studio's
 * SQLite driver, an `ALTER TABLE ... MODIFY ... AUTO_INCREMENT` (which phpMyAdmin
 * writes for every table) clears the key from DESCRIBE, so WP-CLI skips those
 * tables and reports "0 replacements". This helper reads keys from SHOW KEYS
 * instead and replaces values with WP-CLI's own SearchReplacer, which handles
 * PHP-serialised data.
 *
 * Usage:
 *   studio wp --path <site> eval-file studio-search-replace.php <dry|apply> <host[,host...]> <new-url>
 *
 * Matches http and https, with or without www, and JSON-escaped slashes
 * (https:\/\/host), stopping at the end of the host name.
 *
 * @package ls-wp-db-migrate
 */

if ( ! defined( 'WP_CLI' ) || ! class_exists( 'WP_CLI\SearchReplacer' ) ) {
	fwrite( STDERR, "Run this file with: studio wp eval-file studio-search-replace.php <dry|apply> <hosts> <new-url>\n" );
	exit( 2 );
}

global $wpdb;

$ls_mode  = $args[0] ?? '';
$ls_hosts = array_filter( array_map( 'trim', explode( ',', strtolower( $args[1] ?? '' ) ) ) );
$ls_to    = $args[2] ?? '';

if ( ! in_array( $ls_mode, array( 'dry', 'apply' ), true ) || ! $ls_hosts || ! $ls_to ) {
	WP_CLI::error( 'Usage: eval-file studio-search-replace.php <dry|apply> <host[,host...]> <new-url>' );
}
foreach ( $ls_hosts as $ls_host ) {
	if ( ! preg_match( '/^[a-z0-9.-]+(:\d+)?$/', $ls_host ) ) {
		WP_CLI::error( "Invalid host: $ls_host" );
	}
}
$ls_parts = wp_parse_url( $ls_to );
if ( empty( $ls_parts['scheme'] ) || empty( $ls_parts['host'] ) || ! in_array( $ls_parts['scheme'], array( 'http', 'https' ), true ) ) {
	WP_CLI::error( "Invalid new URL: $ls_to" );
}
$ls_dest = $ls_parts['host'] . ( isset( $ls_parts['port'] ) ? ':' . $ls_parts['port'] : '' );

$ls_hosts = array_map( fn( $h ) => preg_replace( '/^www\./', '', $h ), $ls_hosts );
$ls_group = implode( '|', array_map( fn( $h ) => preg_quote( $h, '~' ), $ls_hosts ) );
// (\\\\?/) keeps a JSON-escaped slash; the lookahead stops at the host's end.
$ls_pattern     = 'https?:(\\\\?/)(\\\\?/)(?:www\.)?(?:' . $ls_group . ')(?!\.?[\w-])';
$ls_replacement = $ls_parts['scheme'] . ':${1}${2}' . $ls_dest;
$ls_replacer    = new \WP_CLI\SearchReplacer( $ls_pattern, $ls_replacement, false, true, 'i', '~' );

$ls_apply   = 'apply' === $ls_mode;
$ls_total   = 0;
$ls_rows    = array();
$ls_skipped = array();

foreach ( $wpdb->get_col( $wpdb->prepare( 'SHOW TABLES LIKE %s', $wpdb->esc_like( $wpdb->prefix ) . '%' ) ) as $ls_table ) {
	$ls_pk = array();
	foreach ( $wpdb->get_results( "SHOW KEYS FROM `$ls_table`" ) as $ls_key ) {
		if ( 'PRIMARY' === $ls_key->Key_name ) {
			$ls_pk[ (int) $ls_key->Seq_in_index ] = $ls_key->Column_name;
		}
	}
	ksort( $ls_pk );
	$ls_pk      = array_values( $ls_pk );
	$ls_changes = 0;
	$ls_missed  = 0;

	foreach ( $wpdb->get_results( "DESCRIBE `$ls_table`" ) as $ls_col ) {
		if ( ! preg_match( '/char|text|blob|json|enum|set/i', $ls_col->Type ) || in_array( $ls_col->Field, $ls_pk, true ) ) {
			continue;
		}
		$ls_c     = str_replace( '`', '``', $ls_col->Field );
		$ls_where = implode(
			' OR ',
			array_map( fn( $h ) => $wpdb->prepare( "`$ls_c` LIKE %s", '%' . $wpdb->esc_like( $h ) . '%' ), $ls_hosts )
		);
		if ( ! $ls_pk ) {
			$ls_missed += (int) $wpdb->get_var( "SELECT COUNT(*) FROM `$ls_table` WHERE $ls_where" );
			continue;
		}
		$ls_select = implode( ', ', array_map( fn( $p ) => '`' . str_replace( '`', '``', $p ) . '`', $ls_pk ) );
		foreach ( $wpdb->get_results( "SELECT $ls_select, `$ls_c` AS ls_value FROM `$ls_table` WHERE $ls_where", ARRAY_A ) as $ls_row ) {
			$ls_new = $ls_replacer->run( $ls_row['ls_value'] );
			if ( $ls_new === $ls_row['ls_value'] ) {
				continue;
			}
			++$ls_changes;
			if ( $ls_apply ) {
				unset( $ls_row['ls_value'] );
				if ( false === $wpdb->update( $ls_table, array( $ls_col->Field => $ls_new ), $ls_row ) ) {
					WP_CLI::error( "Update failed in $ls_table.{$ls_col->Field}: {$wpdb->last_error}" );
				}
			}
		}
	}
	if ( $ls_changes ) {
		$ls_rows[] = array(
			'table'   => $ls_table,
			'changes' => $ls_changes,
		);
		$ls_total += $ls_changes;
	}
	if ( $ls_missed ) {
		$ls_skipped[] = "$ls_table ($ls_missed)";
	}
}

if ( $ls_rows ) {
	WP_CLI\Utils\format_items( 'table', $ls_rows, array( 'table', 'changes' ) );
}
if ( $ls_skipped ) {
	WP_CLI::warning( 'Tables without a primary key were not changed; values still matching: ' . implode( ', ', $ls_skipped ) );
}
if ( $ls_apply ) {
	wp_cache_flush();
	WP_CLI::success( "Updated $ls_total value(s)." );
} else {
	WP_CLI::success( "$ls_total value(s) would be updated. Run again with apply to write them." );
}
