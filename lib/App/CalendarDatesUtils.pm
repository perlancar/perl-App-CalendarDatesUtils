package App::CalendarDatesUtils;

# DATE
# VERSION

use 5.010001;
use strict 'subs', 'vars';
use warnings;

our %SPEC;

$SPEC{list_calendar_dates_modules} = {
    v => 1.1,
    summary => 'List Calendar::Dates::* modules, without the prefix',
};
sub list_calendar_dates_modules {
    require PERLANCAR::Module::List;

    my $mods = PERLANCAR::Module::List::list_modules(
        "Calendar::Dates::", {list_modules=>1, recurse=>1});
    my @res = sort keys %$mods;
    for (@res) { s/\ACalendar::Dates::// }
    [200, "OK" ,\@res];
}

$SPEC{list_calendar_dates} = {
    v => 1.1,
    summary => 'List dates from one or more Calendar::Dates::* modules',
    args => {
        year => {
            schema => 'int*',
            pos => 0,
            tags => ['category:entry-filtering'],
        },
        month => {
            schema => ['int*', in=>[1, 12]],
            pos => 1,
            tags => ['category:entry-filtering'],
        },
        day => {
            schema => ['int*', in=>[1, 31]],
            pos => 2,
            tags => ['category:entry-filtering'],
        },
        modules => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'modules',
            schema => ['array*', of=>'perl::modname*'],
            cmdline_aliases => {m=>{}},
            'x.element_completion' => [perl_modname => {ns_prefix=>'Calendar::Dates::'}],
            tags => ['category:module-selection'],
        },
        all_modules => {
            summary => 'Use all installed Calendar::Dates::* modules',
            schema => 'true*',
            cmdline_aliases => {a=>{}},
            tags => ['category:module-selection'],
        },
        all_entries => {
            summary => 'Return all entries (include low-priority ones)',
            schema => 'true*',
            cmdline_aliases => {A=>{}},
            description => <<'_',

By default, low-priority entries (entries tagged `low-priority`) are not
included. This option will include those entries.

_
            tags => ['category:entry-filtering'],
        },
        include_tags => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'include_tag',
            schema => ['array*', of=>'str*'],
            cmdline_aliases => {t=>{}},
            tags => ['category:entry-filtering'],
        },
        exclude_tags => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'exclude_tag',
            schema => ['array*', of=>'str*'],
            cmdline_aliases => {T=>{}},
            tags => ['category:entry-filtering'],
        },
        detail => {
            schema => 'bool*',
            cmdline_aliases => {l=>{}},
        },
    },
    args_rels => {
        req_one => ['modules', 'all_modules'],
    },
};
sub list_calendar_dates {
    my %args = @_;

    my $year = $args{year} // (localtime)[5]+1900;
    my $mon  = $args{month};
    my $day  = $args{day};

    my $modules;
    if ($args{all}) {
        $modules = list_calendar_dates_modules()->[2];
    } else {
        $modules = $args{modules};
    }

    my $params = {};
    $params->{include_tags} = delete $args{include_tags}
        if $args{include_tags};
    $params->{exclude_tags} = delete $args{exclude_tags}
        if $args{exclude_tags};
    $params->{all} = delete $args{all_entries};

    my @rows;
    for my $mod (@$modules) {
        $mod = "Calendar::Dates::$mod" unless $mod =~ /\ACalendar::Dates::/;
        (my $mod_pm = "$mod.pm") =~ s!::!/!g;
        require $mod_pm;

        my $res;
        eval { $res = $mod->get_entries($params, $year, $mon, $day) };
        if ($@) {
            warn "Can't get entries from $mod: $@, skipped";
            next;
        }

        push @rows, @$res;
    }

    unless ($args{detail}) {
        @rows = map {$_->{date}} @rows;
    }

    [200, "OK", \@rows];
}

1;
#ABSTRACT: Utilities related to Calendar::Dates

=head1 DESCRIPTION

This distributions provides the following command-line utilities:

# INSERT_EXECS_LIST


=head1 SEE ALSO

=cut
