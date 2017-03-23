# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=6

VALA_MIN_API_VERSION=0.22

inherit vala cmake-utils bzr

DESCRIPTION="Switchboard plug to show displays information"
HOMEPAGE="http://launchpad.net/switchboard-plug-display"
EBZR_REPO_URI="lp:switchboard-plug-about"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~x86 ~amd64"
IUSE="nls"

RDEPEND="
	x11-libs/granite
	x11-libs/gtk+:3
	gnome-base/gnome-desktop:3
	>=pantheon-base/switchboard-2"
DEPEND="${RDEPEND}
	$(vala_depend)
	virtual/pkgconfig
	nls? ( sys-devel/gettext )"

src_prepare() {
	use nls || sed -i '/add_subdirectory (po)/d' CMakeLists.txt

	cmake-utils_src_prepare
	vala_src_prepare
}

src_configure() {
	local mycmakeargs=(
		-DVALA_EXECUTABLE="${VALAC}"
	)
	cmake-utils_src_configure
}
