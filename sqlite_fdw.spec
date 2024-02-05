%global sname	sqlite_fdw

# Disable tests by default.
%{!?runselftest:%global runselftest 0}

%ifarch ppc64 ppc64le s390 s390x armv7hl
 %if 0%{?rhel} && 0%{?rhel} == 7
  %{!?llvm:%global llvm 0}
 %else
  %{!?llvm:%global llvm 1}
 %endif
%else
 %{!?llvm:%global llvm 1}
%endif

Summary:	SQLite Foreign Data Wrapper for PGSpider
Name:		%{sname}_%{pgmajorversion}
Version:	%{?release_version}
Release:	%{?dist}
License:	TOSHIBA CORPORATION
URL:		https://github.com/pgspider/%{sname}
Source0:	sqlite_fdw.tar.bz2
BuildRequires:	pgspider%{pgmajorversion}-devel pgdg-srpm-macros
BuildRequires:	pgspider%{pgmajorversion}-server
BuildRequires:  sqlite >= 3.42.0
Requires:	pgspider%{pgmajorversion}-server
%if 0%{?fedora} >= 27
Requires:	sqlite-libs
%endif
%if 0%{?rhel} <= 7
Requires:	sqlite
%endif

%description
This PGSpider extension is a Foreign Data Wrapper for SQLite.

%if %llvm
%package llvmjit
Summary:	Just-in-time compilation support for sqlite_fdw
Requires:	%{name}%{?_isa} = %{version}-%{release}
%if 0%{?rhel} && 0%{?rhel} == 7
%ifarch aarch64
Requires:	llvm-toolset-7.0-llvm >= 7.0.1
%else
Requires:	llvm5.0 >= 5.0
%endif
%endif
%if 0%{?suse_version} >= 1315 && 0%{?suse_version} <= 1499
BuildRequires:	llvm6-devel clang6-devel
Requires:	llvm6
%endif
%if 0%{?suse_version} >= 1500
BuildRequires:	llvm15-devel clang15-devel
Requires:	llvm15
%endif
%if 0%{?fedora} || 0%{?rhel} >= 8
Requires:	llvm => 13.0
%endif

%description llvmjit
This packages provides JIT support for sqlite_fdw
%endif

%prep

%setup -q -n %{sname}-%{version}

%build

USE_PGXS=1 PATH=%{pginstdir}/bin/:$PATH %{__make} %{?_smp_mflags}

%install
%{__rm} -rf %{buildroot}
USE_PGXS=1 PATH=%{pginstdir}/bin/:$PATH %{__make} %{?_smp_mflags} install DESTDIR=%{buildroot}

# Install README and howto file under PGSpider installation directory:
%{__install} -d %{buildroot}%{pginstdir}/doc/extension
%{__install} -m 644 README.md %{buildroot}%{pginstdir}/doc/extension/README-%{sname}.md
%{__rm} -f %{buildroot}%{pginstdir}/doc/extension/README.md

%files
%defattr(-,root,root,-)
%{pginstdir}/lib/*.so
%{pginstdir}/share/extension/*.sql
%{pginstdir}/share/extension/*.control
%{pginstdir}/doc/extension/README-%{sname}.md

%if %llvm
%files llvmjit
   %{pginstdir}/lib/bitcode/%{sname}*.bc
   %{pginstdir}/lib/bitcode/%{sname}/*.bc
%endif

%changelog
* Wed Sep 27 2023 t-kataym - 2.4.0
- Support PosgreSQL 16.0
- Add text transformations for pg DB encoding
- Add updatable option on different levels
- Improve error message
- Refactor README.md
- Fix bugs

* Tue Jan 17 2023 t-kataym - 2.3.0
- Support PostgreSQL 15.0
- Bug fix of error handling in case of sqlite busy

* Mon Sep 26 2022 t-kataym - 2.2.0
- Support PostgreSQL 15beta4
- Support push down CASE expressions

* Wed Dec 22 2021 t-kataym - 2.1.1
- Support Insert/Update with generated column
- Support check invalid options
- Bug fixings:
        - Fix issue #44 on GitHub (FTS Virtual Table crash)
        - Fix memory leak

* Fri Sep 24 2021 hrkuma - 2.1.0
- Support version 14 related features
-  Support TRUNCATE
-  Support Bulk Insert
-  Support keep connection control and connection cache information
- Refactored tests

* Wed May 26 2021 hrkuma - 2.0.0
- Support JOIN pushdown (LEFT,RIGHT,INNER)
- Support direct modification (UPDATE/DELETE)
- Support pushdown nest functions
- Support pushdown scalar operator ANY/ALL (ARRAY)
- Support pushdown ON CONFLICT DO NOTHING
- Refactored tests
- Bug fixings
-  Don't push down lower/upper function
-  Fix processing for DATE data type
-  Do not prepare SQL statement during EXPLAIN

* Thu Jan 14 2021 hrkuma - 1.3.1
- Support function pushdown in the target list (for PGSpider)
- Support Windows build using Visual Studio project
- Fix FETCH ... WITH TIES issue
- Fix sqlite_fdw does not bind the correct numeric value when it is sub-query