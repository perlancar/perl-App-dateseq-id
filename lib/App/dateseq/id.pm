package App::dateseq::id;

# AUTHORITY
# DATE
# DIST
# VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use App::dateseq ();
use Perinci::Sub::Util qw(gen_modified_sub);

gen_modified_sub(
    base_name => 'App::dateseq::dateseq',
    output_name => 'dateseq_id',
    add_args => {
        holiday => {
            summary => 'Only list holidays (or non-holidays)',
            schema => 'bool*',
            tags => ['category:filtering'],
        },
        include_joint_leave => {
            summary => 'Whether to assume joint leave days as holidays',
            schema => 'bool*',
            tags => ['category:filtering'],
            cmdline_aliases => {j=>{}},
        },
    },
    modify_meta => sub {
        my $meta = shift;
        $meta->{examples} = [
            {
                summary => 'List Indonesian holidays between 2020-01-01 to 2021-12-31',
                src => '[[prog]] 2020-01-01 2021-12-13 --holiday',
                src_plang => 'bash',
                test => 0,
                'x.doc.show_result' => 0,
            },
            {
                summary => 'List the last non-holiday business day of each month in 2021',
                src => '[[prog]] 2021-12-31 2021-01-01 -r --noholiday -j --business --limit-monthly 1',
                src_plang => 'bash',
                test => 0,
                'x.doc.show_result' => 0,
            },
        ];

        $meta->{links} = [
            {url=>'prog:dateseq'},
        ];
    },
    output_code => sub {
        require Calendar::Indonesia::Holiday;

        my %args = @_;

        my $holiday = delete $args{holiday};
        my $inc_jv  = delete $args{include_joint_leave};
        $args{_filter} = sub {
            my $dt = shift;
            my $date = $dt->ymd;
            my $res = Calendar::Indonesia::Holiday::is_id_holiday(date=>$date, detail=>1);
            unless ($res->[0] == 200) {
                log_error "Cannot determine if %s is a holiday: %s", $date, $res;
                return 0;
            }
            my $is_holiday = $res->[2];
            unless (defined $is_holiday) {
                log_error "Cannot determine if %s is a holiday (2): %s", $date, $res->[3]{'cmdline.result'};
                return 0;
            }
            $is_holiday = 0 if $is_holiday && $is_holiday->{is_joint_leave} && !$inc_jv;
            return !($is_holiday xor $holiday);
        };

        App::dateseq::dateseq(%args);
    },
);

1;
# ABSTRACT:

=head1 SEE ALSO

L<App::dateseq>
