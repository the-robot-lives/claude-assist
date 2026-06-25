defmodule GenAI.ModelDetail.Capacity do
  @moduledoc """
  Provides standardized structure for tracking capacity details.

  - requests per minute
  - tokens per minute
  - tokens per day
  - inference_speed
  - vram
  """

  @vsn 1.0
  @type t ::
          %__MODULE__{
            tokens_per_minute: integer | nil,
            requests_per_minute: integer | nil,
            tokens_per_day: integer | nil,
            inference_speed: float | nil,
            vram: integer | nil,
            vsn: float
          }
  defstruct tokens_per_minute: nil,
            requests_per_minute: nil,
            tokens_per_day: nil,
            inference_speed: nil,
            vram: nil,
            vsn: @vsn
end

defmodule GenAI.ModelDetail.Costing do
  @moduledoc """
  Provides standardized structure for tracking costing details.
  - cost per million input tokens
  - cost per million output tokens
  - cost per hour
  - cost per request
  - media costs
  """
  @vsn 1.0
  @type t ::
          %__MODULE__{
            million_input_tokens: float | nil,
            million_output_tokens: float | nil,
            per_request: float | nil,
            per_instance_hour: float | nil,
            # tile_size, base_tokens, tokens_per_tile
            media: map() | nil,
            vsn: float
          }
  defstruct million_input_tokens: nil,
            million_output_tokens: nil,
            per_request: nil,
            per_instance_hour: nil,
            media: nil,
            vsn: @vsn
end

defmodule GenAI.ModelDetail.ModalitySupport do
  @moduledoc """
  Provides standardized structure for tracking modality support details.
    For example if a model can mimic video support by streaming images,
    plus audio transcription. Or supports native image and audio.
  """
  @vsn 1.0
  @type t ::
          %__MODULE__{
            video: any,
            image: any,
            audio: any,
            vsn: float
          }
  defstruct video: nil,
            image: nil,
            audio: nil,
            vsn: @vsn
end

defmodule GenAI.ModelDetail.ToolUsage do
  @moduledoc """
  Provides details on tool usage support: native (api level), prompt injection, no support, etc.
  """
  @vsn 1.0
  @type t :: %__MODULE__{vsn: float}
  defstruct vsn: @vsn
end

defmodule GenAI.ModelDetail.UseCaseSupport do
  @moduledoc """
  Provides standardized structure for tracking use case support details.
  Where use case is the ability of the model to perform a task like feature extraction, generating synthetic memories, etc.
  Tracks both per model fixed scores plus dynamic adjustments based on system/user feedback.
  """
  @vsn 1.0
  @type t :: %__MODULE__{
          use_cases: map(),
          vsn: float
        }
  defstruct use_cases: %{},
            vsn: @vsn
end

defmodule GenAI.ModelDetail.BenchMarks do
  @moduledoc """
  Last reported model evaluation benchmark scores.
  """
  @vsn 1.0
  @type t :: %__MODULE__{
          benchmarks: map(),
          vsn: float
        }
  defstruct benchmarks: %{},
            vsn: @vsn
end

defmodule GenAI.ModelDetail.FineTuning do
  @moduledoc """
  Tracks fine tuning details for the model, if any.
  - Type of fine tuning
  - Fine Tuning Date
  - Fine Tuning Notes
  """

  @vsn 1.0
  @type t :: %__MODULE__{vsn: float}
  defstruct vsn: @vsn
end

defmodule GenAI.ModelDetail.HyperParamSupport do
  @moduledoc """
  Provides standardized structure for tracking hyper parameter support such as allowed values, ranges, mapping etc.
  """
  @vsn 1.0
  @type t :: %__MODULE__{vsn: float}
  defstruct vsn: @vsn
end

defmodule GenAI.ModelDetail.TrainingDetails do
  @moduledoc """
  Provides standardized structure for tracking training details such as training cut off, supplemental_training per subject cut offs, etc. censorship. instruct training, dolphin, etc.
  """
  @vsn 1.0
  @type t :: %__MODULE__{vsn: float}
  defstruct vsn: @vsn
end

defmodule GenAI.ModelDetails do
  @moduledoc """
  Provides standardized structure for tracking extended module details.
  """
  @vsn 1.0
  @type release_status :: :internal | :alpha | :beta | :rc | :stable | :deprecated | nil
  @type support_status :: :supported | :unsupported | :partial | :unknown | nil
  @type capacity :: GenAI.ModelDetail.Capacity.t() | nil
  @type costing :: GenAI.ModelDetail.Costing.t() | nil
  @type modalities :: GenAI.ModelDetail.ModalitySupport.t() | nil
  @type tool_usage :: GenAI.ModelDetail.ToolUsage.t() | nil
  @type use_case_support :: GenAI.ModelDetail.UseCaseSupport.t() | nil
  @type benchmarks :: GenAI.ModelDetail.BenchMarks.t() | nil
  @type fine_tuning :: GenAI.ModelDetail.FineTuning.t() | nil
  @type hyper_param_support :: GenAI.ModelDetail.HyperParamSupport.t() | nil
  @type training_details :: GenAI.ModelDetail.TrainingDetails.t() | nil

  @type t ::
          %__MODULE__{
            release: release_status,
            status: support_status,
            capacity: capacity,
            costing: costing,
            modalities: modalities,
            tool_usage: tool_usage,
            use_cases: use_case_support,
            benchmarks: benchmarks,
            fine_tuning: fine_tuning,
            hyper_params: hyper_param_support,
            training_details: training_details,
            vsn: float
          }

  defstruct release: nil,
            status: nil,
            capacity: nil,
            costing: nil,
            modalities: nil,
            tool_usage: nil,
            use_cases: nil,
            benchmarks: nil,
            fine_tuning: nil,
            hyper_params: nil,
            training_details: nil,
            vsn: @vsn
end
