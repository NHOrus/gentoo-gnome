# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="3"
PYTHON_DEPEND="2:2.4"

inherit eutils flag-o-matic gnome.org gnome2-utils libtool virtualx

DESCRIPTION="Gimp ToolKit +"
HOMEPAGE="http://www.gtk.org/"

LICENSE="LGPL-2"
SLOT="3"
# NOTE: *-macos support is BROKEN. See `quartz-backend` etc in configure
# NOTE: This gtk+ has multi-gdk-backend support, see:
#  * http://blogs.gnome.org/kris/2010/12/29/gdk-3-0-on-mac-os-x/
#  * http://mail.gnome.org/archives/gtk-devel-list/2010-November/msg00099.html
# NOTE: Lots of aqua stuff in this ebuild is probably very broken
IUSE="aqua cups debug doc examples +introspection jpeg jpeg2k tiff test vim-syntax xinerama"
if [[ ${PV} = 9999 ]]; then
	inherit gnome2-live
	KEYWORDS=""
else
	KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~sh ~sparc ~x86 ~x86-fbsd ~x86-freebsd ~x86-interix ~amd64-linux ~x86-linux ~ppc-macos ~x86-macos ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris"
fi

# NOTE: cairo[svg] dep is due to bug 291283 (not patched to avoid eautoreconf)
RDEPEND="!aqua? (
		x11-libs/libXrender
		x11-libs/libX11
		x11-libs/libXi
		x11-libs/libXt
		x11-libs/libXext
		>=x11-libs/libXrandr-1.3
		x11-libs/libXcursor
		x11-libs/libXfixes
		x11-libs/libXcomposite
		x11-libs/libXdamage
		>=x11-libs/cairo-1.10.0[X,svg]
		>=x11-libs/gdk-pixbuf-2.21:2[X,introspection?,jpeg?,jpeg2k?,tiff?]
	)
	aqua? (
		>=x11-libs/cairo-1.10.0[aqua,svg]
		>=x11-libs/gdk-pixbuf-2.21:2[introspection?,jpeg?,jpeg2k?,tiff?]
	)
	xinerama? ( x11-libs/libXinerama )
	>=dev-libs/glib-2.27.5
	>=x11-libs/pango-1.20[introspection?]
	>=dev-libs/atk-1.29.2[introspection?]
	media-libs/fontconfig
	x11-misc/shared-mime-info
	cups? ( net-print/cups )
	introspection? ( >=dev-libs/gobject-introspection-0.9.3 )
	!<gnome-base/gail-1000"
DEPEND="${RDEPEND}
	>=dev-util/pkgconfig-0.9
	!aqua? (
		x11-proto/xextproto
		x11-proto/xproto
		x11-proto/inputproto
		x11-proto/damageproto
	)
	x86-interix? (
		sys-libs/itx-bind
	)
	xinerama? ( x11-proto/xineramaproto )
	>=dev-util/gtk-doc-am-1.11
	doc? (
		>=dev-util/gtk-doc-1.11
		~app-text/docbook-xml-dtd-4.1.2 )
	test? (
		media-fonts/font-misc-misc
		media-fonts/font-cursor-misc )"
PDEPEND="vim-syntax? ( app-vim/gtk-syntax )"

strip_builddir() {
	local rule=$1
	shift
	local directory=$1
	shift
	sed -e "s/^\(${rule} =.*\)${directory}\(.*\)$/\1\2/" -i $@ \
		|| die "Could not strip director ${directory} from build."
}

src_prepare() {
	# -O3 and company cause random crashes in applications. Bug #133469
	replace-flags -O3 -O2
	strip-flags

	# Non-working test in gentoo's env
	sed 's:\(g_test_add_func ("/ui-tests/keys-events.*\):/*\1*/:g' \
		-i gtk/tests/testing.c || die "sed 1 failed"
	sed '\%/recent-manager/add%,/recent_manager_purge/ d' \
		-i gtk/tests/recentmanager.c || die "sed 2 failed"

	if use x86-interix; then
		# activate the itx-bind package...
		append-flags "-I${EPREFIX}/usr/include/bind"
		append-ldflags "-L${EPREFIX}/usr/lib/bind"
	fi

	if ! use test; then
		# don't waste time building tests
		strip_builddir SRC_SUBDIRS tests Makefile.am Makefile.in
	fi

	if ! use examples; then
		# don't waste time building demos
		strip_builddir SRC_SUBDIRS demos Makefile.am Makefile.in
	fi

	gnome2_src_prepare
}

src_configure() {
	# FIXME: PackageKit support
	# png always on to display icons (foser)
	local myconf="$(use_enable doc gtk-doc)
		$(use_enable xinerama)
		$(use_enable cups cups auto)
		$(use_enable introspection)
		--disable-packagekit
		--disable-papi"

	# XXX: Maybe with multi-backend we should enable x11 all the time?
	if use aqua; then
		myconf="${myconf} --enable-quartz-backend --disable-xinput"
	else
		myconf="${myconf} --enable-x11-backend --enable-xinput"
	fi

	# Passing --disable-debug is not recommended for production use
	use debug && myconf="${myconf} --enable-debug=yes"

	# need libdir here to avoid a double slash in a path that libtool doesn't
	# grok so well during install (// between $EPREFIX and usr ...)
	econf --libdir="${EPREFIX}/usr/$(get_libdir)" ${myconf}
}

src_compile() {
	# Unfortunately, the parellel make breaks if USE=introspection
	use introspection && export MAKEOPTS="${MAKEOPTS} -j1"
	default
}

src_test() {
	unset DBUS_SESSION_BUS_ADDRESS
	# Exporting HOME fixes tests using XDG directories spec since all defaults
	# are based on $HOME. It is also backward compatible with functions not
	# yet ported to this spec.
	XDG_DATA_HOME="${T}" HOME="${T}" Xemake check || die "tests failed"
}

src_install() {
	emake DESTDIR="${D}" install || die "Installation failed"

	# see bug #133241
	echo 'gtk-fallback-icon-theme = "gnome"' > "${T}/gtkrc"
	insinto /etc/gtk-3.0
	doins "${T}"/gtkrc || die "doins gtkrc failed"

	# Enable xft in environment as suggested by <utx@gentoo.org>
	echo "GDK_USE_XFT=1" > "${T}"/50gtk3
	doenvd "${T}"/50gtk3 || die "doenvd failed"

	dodoc AUTHORS ChangeLog* HACKING NEWS* README* || die "dodoc failed"

	# Remove unneeded *.la files
	find "${ED}" -name "*.la" -delete

	# gtk-update-icon-cache and gtk-builder-convert are provided by gtk+:2 now
	# XXX: Make sure the gtk+:2 and gtk+:3 versions haven't diverged!
	rm -v "${ED}"/usr/bin/gtk-{builder-convert,update-icon-cache} || die

	# add -framework Carbon to the .pc files
	use aqua && for i in gtk+-3.0.pc gtk+-quartz-3.0.pc gtk+-unix-print-3.0.pc; do
		sed -i -e "s:Libs\: :Libs\: -framework Carbon :" "${ED}"usr/$(get_libdir)/pkgconfig/$i || die "sed failed"
	done
}

pkg_preinst() {
	gnome2_schemas_savelist
}

pkg_postinst() {
	gnome2_schemas_update

	local GTK3_MODDIR="${EROOT}usr/$(get_libdir)/gtk-3.0/3.0.0"
	gtk-query-immodules-3.0  > "${GTK3_MODDIR}/immodules.cache" \
		|| ewarn "Failed to run gtk-query-immodules-3.0"

	if ! has_version "app-text/evince"; then
		elog "Please install app-text/evince for print preview functionality."
		elog "Alternatively, check \"gtk-print-preview-command\" documentation and"
		elog "add it to your gtkrc."
	fi
}

pkg_postrm() {
	gnome2_schemas_update --uninstall
}
