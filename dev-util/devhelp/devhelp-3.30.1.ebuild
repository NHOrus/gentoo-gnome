# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6
PYTHON_COMPAT=( python{3_5,3_6,3_7} )

inherit gnome2 python-single-r1 toolchain-funcs meson

DESCRIPTION="An API documentation browser for GNOME"
HOMEPAGE="https://wiki.gnome.org/Apps/Devhelp"

LICENSE="GPL-2+"
SLOT="0/3-1" # subslot = 3-(libdevhelp-3 soname version)
KEYWORDS="~alpha amd64 ~arm ~ia64 ~ppc ~ppc64 ~sparc x86 ~amd64-fbsd ~x86-fbsd"
IUSE=""
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

COMMON_DEPEND="
	>=dev-libs/glib-2.37.3:2[dbus]
	>=x11-libs/gtk+-3.19.3:3
	>=net-libs/webkit-gtk-2.20:4
	>=dev-libs/amtk-5.0.0
"
RDEPEND="${COMMON_DEPEND}
	${PYTHON_DEPS}
	app-editors/gedit[introspection,python,${PYTHON_USEDEP}]
	dev-python/pygobject:3[${PYTHON_USEDEP}]
	x11-libs/gtk+[introspection]
	gnome-base/gsettings-desktop-schemas
"
DEPEND="${COMMON_DEPEND}
	${PYTHON_DEPS}
	>=dev-util/intltool-0.40
	gnome-base/gnome-common
	virtual/pkgconfig
"

pkg_setup() {
	python-single-r1_pkg_setup
}

src_prepare() {
	gnome2_src_prepare
}
