module PACKMAN
  # Version should be organized in the following format:
  # => major.minor[[-]alpha|beta|release_candidate].revision
  class VersionSpec
    attr_reader :major, :minor, :revision, :alpha, :beta, :release_candidate

    def initialize version_string
      tmp = version_string.split('.')
      # The major version identifer is the first one.
      begin
        @major = Integer(tmp[0])
      rescue
        PACKMAN::CLI.report_error "Bad version identifer #{PACKMAN::CLI.red version_string}!"
      end
      # The alpha, beta, release candidate identifers may be appended to the
      # minor version identifer
      return if tmp.size == 1
      res = tmp[1].match(/(\d+)-?(a|b|rc)?(\d+)?/)
      # TODO: Handle bad minor version identifer.
      if not res
        PACKMAN::CLI.report_error "Bad version identifer #{PACKMAN::CLI.red version_string}!"
      end
      @minor = res[1].to_i
      if res[2] and res[3]
        case res[2]
        when 'a'
          @alpha = res[3].to_i
        when 'b'
          @beta = res[3].to_i
        when 'rc'
          @release_candidate = res[3].to_i
        end
      elsif res[2] and not res[3]
        PACKMAN::CLI.report_error "Bad version identifer #{PACKMAN::CLI.red version_string}!"
      end
      return if tmp.size == 2
      @revision = tmp[2].to_i
      if tmp.size > 3
        PACKMAN::CLI.report_error "Bad version identifer #{PACKMAN::CLI.red version_string}!"
      end
    end

    def >= other
      PACKMAN::CLI.report_error "Invalid argument #{other}!" if other.class != VersionSpec
      return false if self.major and other.major and self.major < other.major
      return true  if self.major and other.major and self.major > other.major
      return false if self.minor and other.minor and self.minor < other.minor
      return true  if self.minor and other.minor and self.minor > other.minor
      return false if self.revision and other.revision and self.revision < other.revision
      return true  if self.revision and other.revision and self.revision > other.revision
      return false if self.alpha and other.alpha and self.alpha < other.alpha
      return true  if self.alpha and other.alpha and self.alpha > other.alpha
      return false if self.beta and other.beta and self.beta < other.beta
      return true  if self.beta and other.beta and self.beta > other.beta
      return false if self.release_candidate and other.release_candidate and self.release_candidate < other.release_candidate
      return true  if self.release_candidate and other.release_candidate and self.release_candidate > other.release_candidate
      return true
    end

    def == other
      PACKMAN::CLI.report_error "Invalid argument #{other}!" if other.class != VersionSpec
      return false if (self.major and not other.major) or (not self.major and other.major)
      return false if self.major and other.major and self.major != other.major
      return false if (self.minor and not other.major) or (not self.minor and other.minor)
      return false if self.minor and other.minor and self.minor != other.minor
      return false if (self.revision and not other.revision) or (not self.revision and other.revision)
      return false if self.revision and other.revision and self.revision != other.revision
      return false if (self.alpha and not other.alpha) or (not self.alpha and other.alpha)
      return false if self.alpha and other.alpha and self.alpha != other.alpha
      return false if (self.beta and not other.beta) or (not self.beta and other.beta)
      return false if self.beta and other.beta and self.beta != other.beta
      return false if (self.release_candidate and not other.release_candidate) or (not self.release_candidate and other.release_candidate)
      return false if self.release_candidate and other.release_candidate and self.release_candidate != other.release_candidate
      return true
    end

    def =~ other
      PACKMAN::CLI.report_error "Invalid argument #{other}!" if other.class != VersionSpec
      return false if not self.major and other.major
      return false if self.major and other.major and self.major != other.major
      return false if not self.minor and other.minor
      return false if self.minor and other.minor and self.minor != other.minor
      return false if not self.revision and other.revision
      return false if self.revision and other.revision and self.revision != other.revision
      return false if not self.alpha and other.alpha
      return false if self.alpha and other.alpha and self.alpha != other.alpha
      return false if not self.beta and other.beta
      return false if self.beta and other.beta and self.beta != other.beta
      return false if not self.release_candidate and other.release_candidate
      return false if self.release_candidate and other.release_candidate and self.release_candidate != other.release_candidate
      return true
    end

    def to_s
      res = "#{major}" if major
      res << ".#{minor}" if minor
      res << "a#{alpha}" if alpha
      res << "b#{beta}" if beta
      res << "rc#{release_candidate}" if release_candidate
      res << ".#{revision}" if revision
      return res
    end

    def self.validate version_string
      tmp = version_string.match(/(>=|==|=~)?(.*)/)
      VersionSpec.new tmp[2]
    end
  end
end