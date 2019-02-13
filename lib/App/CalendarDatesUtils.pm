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
    summary => 'List dates from a Calendar::Dates::* module',
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
        module => {
            schema => 'perl::modname*',
            req => 1,
            cmdline_aliases => {m=>{}},
            'x.completion' => [perl_modname => {ns_prefix=>'Calendar::Dates'}],
        },
        detail => {
            schema => 'bool*',
            cmdline_aliases => {l=>{}},
        },
    },
};
sub list_calendar_dates {
    my %args = @_;

    my $year = $args{year} // (localtime)[5]+1900;
    my $mon  = $args{month};
    my $day  = $args{day};

    my $mod = $args{module};
    $mod = "Calendar::Dates::$mod" unless $mod =~ /\ACalendar::Dates::/;
    (my $mod_pm = "$mod.pm") =~ s!::!/!g;
    require $mod_pm;

    my $rows = $mod->get_entries($year, $mon, $day);

    unless ($args{detail}) {
        $rows = [map {$_->{date}} @$rows];
    }

    [200, "OK", $rows];
}

1;
#ABSTRACT: Utilities related to Calendar::Dates

=head1 DESCRIPTION

This distributions provides the following command-line utilities:

# INSERT_EXECS_LIST


=head1 SEE ALSO

=cut
