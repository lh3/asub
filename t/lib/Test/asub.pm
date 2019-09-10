package
    Test::asub;
use Getopt::Long ();
use File::Basename 'dirname';
use File::Spec::Functions 'catfile';
use File::Temp qw{tempdir tempfile};
use IPC::Run 'run';
use Cwd ();
use feature 'state';

use constant COLLECT_COVERAGE => $INC{'Devel/Cover.pm'} ? 1 : 0;

sub asub_arguments_ok {
    my ($self, $out, %tests) = (shift, shift, @_);
    my $asub = $self->pipeline_asub_command($out);
    Getopt::Long::Configure(qw{pass_through bundling});
    my %parsed;
    my ($ret, $args) = Getopt::Long::GetOptionsFromString($asub,
        'G'   => \$parsed{group},
        'g=i' => \$parsed{group_size},
        'k=s' => \$parsed{index});
    $self->_test(is =>$ret, 1, 'success');
    for my $name(keys %tests) {
        $self->_test(subtest => $name,
                     sub {
                         $tests{$name}->({ %parsed });
                     });
    }
    $self;
}

sub asub_compile_ok {
    my ($self, $stdout, $stderr) = (shift);
    my $pid = run [$^X, '-c', $self->asub_path], \undef, \$stdout, \$stderr;
    return $self->_test(like => $stderr, qr/syntax OK$/);
}

sub asub_farm_run_ok {
    my ($self, $stdout, $stderr) = (shift);
    my $cmd = $self->{command};
    my $pid = run $cmd, \undef, \$stdout, \$stderr;
    $self->_test(ok => $pid);
    return ($stdout, $stderr);
}

sub asub_help_ok {
    my ($self, $stdout, $stderr) = (shift);
    my $pid = run([$self->_executable_opts],
                  \*STDIN, \$stdout, \$stderr);
    return $self->_test(like => $stderr, qr/Program: asub/);
}

sub asub_path {
    state $asub = catfile Cwd::getcwd(), 'asub';
}

sub asub_run_ok {
    my ($self, $path, $commands, $stdout, $stderr) = (shift, shift, shift);
    local $ENV{PATH} = join ':', $path, $self->_prune_path();
    # change to temp dir to stop filling current directory
    my $dir = tempdir();
    chdir($dir) or $self->_test(fail => "chdir $dir");
    my $pid = run([$self->_executable_opts, '-p', @_],
                  \$commands, \$stdout, \$stderr);
    $self->_test(ok => $pid);
    # change back...
    chdir dirname($self->asub_path) or $self->_test(fail => "chdir checkout base");
    return ($stdout, $stderr);
}

sub asub_run_ok_with_lsf {
    my $self = shift;
    my ($out, $err) = $self->asub_run_ok($self->lsf_mock_bin, @_);
    $self->pipeline_runs_command($out, qr/^bsub/, 'LSF submission command');
    return ($out, $err);
}

sub asub_run_ok_with_sge {
    my $self = shift;
    my ($out, $err) = $self->asub_run_ok($self->sge_mock_bin, @_);
    $self->pipeline_runs_command($out, qr/^qsub/, 'SGE submission command');
    return ($out, $err);
}

sub asub_run_ok_with_slurm {
    my $self = shift;
    my ($out, $err) = $self->asub_run_ok($self->slurm_mock_bin, @_);
    $self->pipeline_runs_command($out, qr/^sbatch/, 'Slurm submission command');
    return ($out, $err);
}

sub farm_context {
    my ($self, $max_commands, @serial) = (shift, shift || 10, grep { $_ eq '-G' } @_);
    $self->{job_id}  = @serial ? 1 : int rand $max_commands;
    $self->{job_id}||= 1;
    $self->{script}  = catfile tempdir(), 'farm.sh';
    $self->{group}   = @serial ? $max_commands : 1;
    $self->{command} = [ $self->_executable_opts, @serial,
                         '-g' => $self->{group},
                         '-k' => $self->{job_id},
                         $self->{script} ];
    $self;
}

sub lsf_mock_bin {
    catfile mock_bin(), qw{lsf bin};
}

sub mock_bin {
    state $mock_bin = catfile Cwd::getcwd(), qw{t mock};
}

sub new { 
    asub_path();
    mock_bin();
    return bless {}, __PACKAGE__;
}

sub pipeline_asub_command {
    my ($self, $pipeline) = (shift, shift);
    my (@pipeline) = split /\s\|\s/ => $pipeline;
    my $asub_path  = $self->asub_path;
    (my $asub = $pipeline[0]) =~ s/^.*($asub_path[^']+)'$/$1/;
    # for tests this should be true
    $self->_test(like => $asub, qr{^$asub_path}, 'regex success');
    return $asub;
}

sub pipeline_runs_command {
    my ($self, $pipeline) = (shift, shift);
    my (@pipeline) = split /\s\|\s/ => $pipeline;
    return $self->_test(like => $pipeline[1], @_);
}

sub sge_mock_bin {
    catfile mock_bin(), qw{sge bin};
}

sub slurm_mock_bin {
    catfile mock_bin(), qw{slurm bin};
}

sub success { return $_[0]{success} if @_ == 1; $_[0]{success} = $_[1]; $_[0]; }

sub write_farm_script {
    my ($self, @commands) = (@_);
    return $self unless $self->{script};
    open my $fh, '>', $self->{script} or $self->_test(fail => 'failed opening');
    print $fh join "\n" => @commands;
    close $fh;
    warn "Too few commands" unless $#commands >= $self->{job_id};
    return $self;
}

sub _executable_opts {
    my $self = shift;
    (my $hps = $ENV{HARNESS_PERL_SWITCHES} // '') =~ s/^\s+//;
    return ($^X, (COLLECT_COVERAGE ? $hps : ()),
            $self->asub_path);
}

sub _prune_path {
    my $lsf   = 'bsub';
    my $slurm = 'sbatch';
    my $sge   = 'qsub';
    my @parts = grep {
        !(-x catfile $_, $slurm) && 
            !(-x catfile $_, $lsf) &&
            !(-x catfile $_, $sge)
    } split m/:/ => $ENV{PATH};
    return join ':' => @parts;
}

sub _test {
    my ($self, $name, @args) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 2;
    return $self->success(!!Test::More->can($name)->(@args));
}

1;
