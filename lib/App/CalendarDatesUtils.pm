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
        },
        month => {
            schema => ['int*', in=>[1, 12]],
            pos => 1,
        },
        day => {
            schema => ['int*', in=>[1, 31]],
            pos => 2,
        },
        modules => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'modules',
            schema => ['array*', of=>'perl::modname*'],
            cmdline_aliases => {m=>{}},
            'x.completion' => [perl_modname => {ns_prefix=>'Calendar::Dates'}],
        },
        all => {
            summary => 'Use all installed Calendar::Dates::* modules',
            schema => 'true*',
            cmdline_aliases => {a=>{}},
        },
        detail => {
            schema => 'bool*',
            cmdline_aliases => {l=>{}},
        },
    },
    args_rels => {
        req_one => ['modules', 'all'],
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

    my @rows;
    for my $mod (@$modules) {
        $mod = "Calendar::Dates::$mod" unless $mod =~ /\ACalendar::Dates::/;
        (my $mod_pm = "$mod.pm") =~ s!::!/!g;
        require $mod_pm;

        my $res;
        eval { $res = $mod->get_entries($year, $mon, $day) };
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
