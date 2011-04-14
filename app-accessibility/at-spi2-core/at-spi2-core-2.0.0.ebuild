# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="3"
GCONF_DEBUG="no"
GNOME2_LA_PUNT="yes"

inherit gnome2

DESCRIPTION="D-Bus accessibility specifications and registration daemon"
HOMEPAGE="http://live.gnome.org/Accessibility"

LICENSE="LGPL-2"
SLOT="2"
KEYWORDS="~amd64"
IUSE="doc +introspection"

RDEPEND="
	>=dev-libs/glib-2.28:2
	>=sys-apps/dbus-1
	x11-libs/libX11
	x11-libs/libXi
	x11-libs/libXtst
	introspection? ( >=dev-libs/gobject-introspection-0.9.6 )
"
DEPEND="${DEPEND}
	>=dev-util/intltool-0.40
	doc? ( >=dev-util/gtk-doc-1.9 )
"

pkg_setup() {
	DOCS="AUTHORS ChangeLog NEWS README"
	# xevie is deprecated/broken since xorg-1.6/1.7
	G2CONF="${G2CONF} --disable-xevie"
}
