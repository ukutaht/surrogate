class Surrogate
  module RSpec
    module MessagesFor
      MESSAGES = {
        verb: {
          should: {
            default:    "was never told to <%= subject %>",
            with:       "should have been told to <%= subject %> with <%= inspect_arguments expected_arguments %>, but <%= actual_invocation %>",
            times:      "should have been told to <%= subject %> <%= times_msg expected_times_invoked %> but was told to <%= subject %> <%= times_msg times_invoked %>",
            with_times: "should have been told to <%= subject %> <%= times_msg expected_times_invoked %> with <%= inspect_arguments expected_arguments %>, but <%= actual_invocation %>",
          },
          should_not: {
            default:    "shouldn't have been told to <%= subject %>, but was told to <%= subject %> <%= times_msg times_invoked %>",
            with:       "should not have been told to <%= subject %> with <%= inspect_arguments expected_arguments %>, but <%= actual_invocation %>",
            times:      "shouldn't have been told to <%= subject %> <%= times_msg expected_times_invoked %>, but was",
            with_times: "should not have been told to <%= subject %> <%= times_msg expected_times_invoked %> with <%= inspect_arguments expected_arguments %>, but <%= actual_invocation %>",
          },
          other: {
            not_invoked: "was never told to",
            invoked_description: "got it",
          },
        },
        noun: {
          should: {
            default:    "was never asked for its <%= subject %>",
            with:       "should have been asked for its <%= subject %> with <%= inspect_arguments expected_arguments %>, but <%= actual_invocation %>",
            times:      "should have been asked for its <%= subject %> <%= times_msg expected_times_invoked %>, but was asked <%= times_msg times_invoked %>",
            with_times: "should have been asked for its <%= subject %> <%= times_msg expected_times_invoked %> with <%= inspect_arguments expected_arguments %>, but <%= actual_invocation %>",
          },
          should_not: {
            default:    "shouldn't have been asked for its <%= subject %>, but was asked <%= times_msg times_invoked %>",
            with:       "should not have been asked for its <%= subject %> with <%= inspect_arguments expected_arguments %>, but <%= actual_invocation %>",
            times:      "shouldn't have been asked for its <%= subject %> <%= times_msg expected_times_invoked %>, but was",
            with_times: "should not have been asked for its <%= subject %> <%= times_msg expected_times_invoked %> with <%= inspect_arguments expected_arguments %>, but <%= actual_invocation %>",
          },
          other: {
            not_invoked: "was never asked",
            invoked_description: "was asked",
          },
        },
      }

      def message_for(language_type, message_category, message_type, binding)
        message = MessagesFor::MESSAGES[language_type][message_category].fetch(message_type)
        ERB.new(message).result(binding)
      end

      def inspect_arguments(arguments)
        inspected_arguments = arguments.map { |argument| inspect_argument argument }
        inspected_arguments << 'no args' if inspected_arguments.empty?
        "`" << inspected_arguments.join(", ") << "'"
      end

      def inspect_argument(to_inspect)
        if RSpec.rspec_mocks_loaded? && to_inspect.respond_to?(:description)
          to_inspect.description
        else
          to_inspect.inspect
        end
      end

      extend self
    end



    class TimesPredicate
      attr_accessor :expected_times_invoked, :comparer
      def initialize(expected_times_invoked=0, comparer=:<)
        self.expected_times_invoked = expected_times_invoked
        self.comparer = comparer
      end

      def matches?(invocations)
        expected_times_invoked.send comparer, invocations.size
      end

      def default?
        expected_times_invoked == 0 && comparer == :<
      end
    end

    class WithFilter
      attr_accessor :args, :block, :pass, :filter_name

      def initialize(args=[], filter_name=:default_filter, &block)
        self.args = args
        self.block = block
        self.pass = send filter_name
        self.filter_name = filter_name
      end

      def filter(invocations)
        invocations.select &pass
      end

      def default?
        filter_name == :default_filter
      end

      private

      def default_filter
        Proc.new { true }
      end

      def args_must_match
        lambda { |invocation| args_match? args, invocation }
      end

      def args_match?(expected_arguments, actual_arguments)
        if expected_arguments.last.kind_of? Proc
          return unless actual_arguments.last.kind_of? Proc
          block_that_tests = expected_arguments.last
          block_to_test = actual_arguments.last
          asserter = Handler::BlockAsserter.new(block_to_test)
          block_that_tests.call asserter
          asserter.match?
        else
          if RSpec.rspec_mocks_loaded?
            rspec_arg_expectation = ::RSpec::Mocks::ArgumentExpectation.new *expected_arguments
            rspec_arg_expectation.args_match? *actual_arguments
          else
            expected_arguments == actual_arguments
          end
        end
      end
    end
  end
end
