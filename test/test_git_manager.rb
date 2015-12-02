require_relative 'test_helper'

require 'git_manager'

class TestGitManager < MiniTest::Test
  def create_repository
    system 'git init -q .'
    system 'touch README'
    system 'git add README'
    system 'git commit -q -m "test" README'
  end

  def test_checkout
    in_tmpdir do
      mkdir_p 'basedir/master'

      chdir 'basedir/master' do
        create_repository

        system 'echo t1 > README'
        system 'git commit -aqm "test"'
        system 'git tag t1'

        system 'echo t2 > README'
        system 'git commit -aqm "test"'
        system 'git tag t2'
      end

      gm = GitManager.new('basedir')
      gm.stub('remote_rails_url', "file://#{Dir.pwd}/basedir/master") do
        gm.checkout('t1')
      end

      assert Dir.exists?('basedir/t1')
      assert_equal "t1\n", File.read('basedir/t1/README')
    end
  end

  def test_release_tags
    in_tmpdir do
      mkdir_p 'basedir/master'

      chdir 'basedir/master' do
        create_repository
        %w(0.9.4.1 2.3.9.pre 3.0.0_RC2 3.2.8.rc1 3.2.14 v4.0.0.beta1 4.0.1).each do |version|
          system "git tag v#{version}"
        end
      end

      expected = %w(v0.9.4.1 v3.2.14 v4.0.1)
      assert_equal expected, GitManager.new('basedir').release_tags.sort
    end
  end

  def test_tag_date
    in_tmpdir do
      mkdir_p 'basedir/master'

      chdir 'basedir/master' do
        create_repository
        %w(0.9.4.1 2.3.9.pre 3.0.0_RC2 3.2.8.rc1 3.2.14 v4.0.0.beta1 4.0.1).each_with_index do |version, idx|
          system "GIT_COMMITTER_DATE='2000-01-#{10 + idx} 01:23:45 -0200' git tag -a -m 'Release' v#{version}"
        end
      end

      git_manager = GitManager.new('basedir')
      assert_equal '2000-01-10 01:23:45 -0200', git_manager.tag_date('v0.9.4.1')
      assert_equal '2000-01-14 01:23:45 -0200', git_manager.tag_date('v3.2.14')
      assert_equal '2000-01-16 01:23:45 -0200', git_manager.tag_date('v4.0.1')
    end
  end

  def test_sha1_and_short_sha1
    in_tmpdir do
      mkdir_p 'basedir/master'

      sha1 = nil
      chdir 'basedir/master' do
        create_repository
        sha1 = `git rev-parse HEAD`.chomp
      end

      git_manager = GitManager.new('basedir')

      assert_equal sha1, git_manager.sha1
      assert_equal sha1[0, 7], git_manager.short_sha1
    end
  end
end
