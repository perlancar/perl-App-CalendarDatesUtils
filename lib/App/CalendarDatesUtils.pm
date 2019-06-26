package App::CalendarDatesUtils;

# DATE
# VERSION

use 5.010001;
use strict 'subs', 'vars';
use warnings;
#use Log::ger;

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
            summary => 'Specify year of dates to list',
            description => <<'_',

The default is to list dates in the current year. You can specify all_years
instead to list dates from all available years.

_
            schema => 'int*',
            pos => 0,
            tags => ['category:filtering'],
        },
        month => {
            schema => ['int*', in=>[1, 12]],
            pos => 1,
            tags => ['category:filtering'],
        },
        day => {
            schema => ['int*', in=>[1, 31]],
            pos => 2,
            tags => ['category:filtering'],
        },
        all_years => {
            summary => 'List dates from all available years '.
                'instead of a single year',
            schema => 'true*',
            tags => ['category:filtering'],
        },
        modules => {
            summary => 'Name(s) of Calendar::Dates::* module (without the prefix)',
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
            tags => ['category:module-selection'],
        },
        params => {
            summary => 'Specify parameters',
            'x.name.is_plural' => 1,
            'x.name.singular' => 'param',
            'schema' => ['hash*', of=>'str*'],
        },
        detail => {
            summary => 'Whether to show detailed record for each date',
            schema => 'bool*',
            cmdline_aliases => {l=>{}},
        },
        past => {
            schema => 'bool*',
            'summary' => "Only show entries that are less than (at least) today's date",
            'summary.alt.bool.not' => "Filter entries that are less than (at least) today's date",
            tags => ['category:filtering'],
        },
    },
    args_rels => {
        'req_one&' => [
            ['modules', 'all_modules'],
        ],
        'choose_one&' => [
            ['year', 'all_years'],
        ],
    },
};
sub list_calendar_dates {
    my %args = @_;

    my @lt = localtime;
    my $year_today = $lt[5]+1900;
    my $mon_today  = $lt[4]+1;
    my $day_today  = $lt[3];
    #log_trace "date_today: %04d-%02d-%02d", $year_today, $mon_today, $day_today;
    #my $date_today = sprintf "%04d-%02d-%02d", $year_today, $mon_today, $day_today;

    my $year = $args{year} // $year_today;
    my $mon  = $args{month};
    my $day  = $args{day};

    my $modules;
    if ($args{all_modules}) {
        $modules = list_calendar_dates_modules()->[2];
    } else {
        $modules = $args{modules};
    }

    my @rows;
    for my $mod (@$modules) {
        $mod = "Calendar::Dates::$mod" unless $mod =~ /\ACalendar::Dates::/;
        (my $mod_pm = "$mod.pm") =~ s!::!/!g;
        require $mod_pm;

        my $years;
        if ($args{all_years}) {
            $years = [ $mod->get_min_year .. $mod->get_max_year ];
        } else {
            $years = [ $year ];
        }

        for my $y (@$years) {
            my $res;
            eval {
                my @args = ($y, $mon, $day);
                if ($args{params} && keys %{$args{params}}) {
                    unshift @args, $args{params};
                }
                $res = $mod->get_entries(@args);
            };
            if ($@) {
                warn "Can't get entries from $mod (year=$y): $@, skipped";
                next;
            }
            for my $item (@$res) {
                if (defined $args{past}) {
                    my $date_cmp =
                        $item->{year}  <=> $year_today ||
                        $item->{month} <=> $mon_today  ||
                        $item->{day}   <=> $day_today;
                    next if  $args{past} &&  $date_cmp >  0;
                    next if !$args{past} &&  $date_cmp <= 0;
                }
                push @rows, $item;
            }
        }
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
