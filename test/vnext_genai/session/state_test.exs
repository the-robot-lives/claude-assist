defmodule GenAI.Session.StateTest do
  use ExUnit.Case,
    async: true

  @moduletag :session

  alias GenAI.Session.State

  import GenAI.Records.Directive
  require GenAI.Records.Directive

  def fixture(scenario \\ :default)

  def fixture(:default) do
    %GenAI.Session.State{}
  end

  def fixture(:access) do
    %GenAI.Session.State{
      directives: [],
      directive_position: 0,
      thread: [],
      thread_messages: %{foo: :foo_msg},
      stack: %{foo: 1},
      data_generators: %{foo: 2},
      options: %{foo: 3},
      settings: %{foo: 4},
      model_settings: %{{:alpha, :beta} => %{bar: 5}},
      provider_settings: %{foo: %{bar: 6}},
      safety_settings: %{foo: 7},
      model: :foo,
      tools: %{foo: 8},
      monitors: %{foo: 9}
    }
  end

  describe "Session.State Access Logic" do
    test "Access Thread Message" do
      sut = fixture(:access)
      entry = get_in(sut, State.entry_path(message_entry(msg: :foo)))
      assert entry == :foo_msg
    end

    test "Access Stack" do
      sut = fixture(:access)
      entry = get_in(sut, State.entry_path(stack_entry(element: :foo)))
      assert entry == 1
    end

    test "Access Data Generators" do
      sut = fixture(:access)
      entry = get_in(sut, State.entry_path(data_generator_entry(generator: :foo)))
      assert entry == 2
    end

    test "Access Options" do
      sut = fixture(:access)
      entry = get_in(sut, State.entry_path(option_entry(option: :foo)))
      assert entry == 3
    end

    test "Access Settings" do
      sut = fixture(:access)
      entry = get_in(sut, State.entry_path(setting_entry(setting: :foo)))
      assert entry == 4
    end

    test "Access Model Settings" do
      sut = fixture(:access)

      entry =
        get_in(
          sut,
          State.entry_path(
            model_setting_entry(
              model: %GenAI.Model{model: :alpha, provider: :beta},
              setting: :bar
            )
          )
        )

      assert entry == 5
    end

    test "Access Provider Settings" do
      sut = fixture(:access)
      entry = get_in(sut, State.entry_path(provider_setting_entry(provider: :foo, setting: :bar)))
      assert entry == 6
    end

    test "Access Safety Settings" do
      sut = fixture(:access)
      entry = get_in(sut, State.entry_path(safety_setting_entry(category: :foo)))
      assert entry == 7
    end

    test "Access Model" do
      sut = fixture(:access)
      entry = get_in(sut, State.entry_path(model_entry()))
      assert entry == :foo
    end

    test "Access Tools" do
      sut = fixture(:access)
      entry = get_in(sut, State.entry_path(tool_entry(tool: :foo)))
      assert entry == 8
    end

    test "Access Monitors" do
      sut = fixture(:access)
      entry = get_in(sut, State.entry_path(monitor_entry(monitor: :foo)))
      assert entry == 9
    end
  end

  describe "Session.State Directives" do
    test "Apply Basic Directive" do
      context = Noizu.Context.system()

      directive = %GenAI.Session.State.Directive{
        source: {:node, :A},
        entries: [
          {setting_entry(setting: :foo), concrete_value(value: :bop)},
          {setting_entry(setting: :biz), concrete_value(value: :boop)}
        ],
        fingerprint: {:node, :A}
      }

      state = fixture()
      session = %GenAI.Thread.Session{state: state}

      {:ok, session} =
        GenAI.Session.State.Directive.apply_directive(directive, session, context, [])

      assert session.state.settings.foo.value == :bop
      assert session.state.settings.biz.value == :boop
    end

    test "Add and apply directives" do
      context = Noizu.Context.system()

      directive_a = %GenAI.Session.State.Directive{
        source: {:node, :A},
        entries: [
          {setting_entry(setting: :foo), concrete_value(value: :bop)},
          {setting_entry(setting: :biz), concrete_value(value: :boop)}
        ],
        fingerprint: {:node, :A}
      }

      directive_b = %GenAI.Session.State.Directive{
        source: {:node, :B},
        entries: [
          {setting_entry(setting: :fiz), concrete_value(value: :fop)},
          {message_entry(msg: :abba),
           concrete_value(value: GenAI.Message.system("Hello World", id: :abba))}
        ],
        fingerprint: {:node, :B}
      }

      session = %GenAI.Thread.Session{state: fixture()}

      {:ok, session} =
        session
        |> GenAI.Thread.Session.append_directive(directive_a, context, [])

      assert GenAI.Thread.Session.pending_directives?(session) == true
      {:ok, session} = GenAI.Thread.Session.apply_directives(session, context, [])
      assert GenAI.Thread.Session.pending_directives?(session) == false
      assert session.state.settings.foo.value == :bop
      assert session.state.settings.biz.value == :boop

      {:ok, session} =
        session
        |> GenAI.Thread.Session.append_directive(directive_b, context, [])

      assert GenAI.Thread.Session.pending_directives?(session) == true
      {:ok, session} = GenAI.Thread.Session.apply_directives(session, context, [])
      assert GenAI.Thread.Session.pending_directives?(session) == false

      assert session.state.settings.fiz.value == :fop
      assert session.state.thread_messages.abba.value.content == "Hello World"
      [msg] = session.state.thread
      assert msg == :abba
    end
  end

  # -------------------------
  # State
  # -------------------------

  # pending directive
  # append directive
  # apply directive

  # effective_value(selector, state, context, options)
  # entry(selector, state, context, options)

  # -------------------------
  # StateEntry
  # -------------------------
  # effective_value(entry, state, context, options)
  # constraint, selector?
  # references
  # impacts
  # updated_on
  # finger_print
end
