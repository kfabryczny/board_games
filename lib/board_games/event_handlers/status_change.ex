defmodule BoardGames.EventHandlers.StatusChange do
  @moduledoc """
  Logic concerned with updating game state when
  the game status changes.
  """

  alias BoardGames.GameState

  @spec handle({GameState.game_status()}, GameState.t()) ::
          {:ok, GameState.t()} | {:error, {atom(), GameState.t()}}
  def handle({status}, state) do
    state
    |> change_game_status(status)
    |> perform_side_effects(status)
  end

  @spec change_game_status(GameState.t(), GameState.game_status()) ::
          {:ok, GameState.t()} | {:error, {atom(), GameState.t()}}
  defp change_game_status(game_state, :playing)
       when length(game_state.players) > 1 and game_state.status == :setup,
       do: {:ok, %{game_state | status: :playing}}

  defp change_game_status(game_state, :over) when game_state.status == :playing,
    do: {:ok, %{game_state | status: :over}}

  defp change_game_status(game_state, _), do: {:error, {:invalid_transition, game_state}}

  @spec perform_side_effects(
          {:ok, GameState.t()} | {:error, {atom(), GameState.t()}},
          GameState.game_status()
        ) ::
          {:ok, GameState.t()} | {:error, {atom(), GameState.t()}}
  defp perform_side_effects({:ok, game_state}, :playing) do
    {:ok,
     %{
       game_state
       | turn_timer_ref: start_turn_timer(game_state.turn_timer_ref),
         turn: List.first(game_state.players)
     }}
  end

  defp perform_side_effects({:ok, game_state}, :over) do
    cancel_tick_timer(game_state.turn_timer_ref)

    {:ok,
     %{
       game_state
       | turn_timer_ref: nil,
         turn: List.first(game_state.players)
     }}
  end

  defp perform_side_effects({:ok, game_state}, _), do: {:ok, game_state}
  defp perform_side_effects({:error, {code, game_state}}, _), do: {:error, {code, game_state}}

  @spec start_turn_timer(nil | reference()) :: reference()
  defp start_turn_timer(nil) do
    Process.send_after(
      self(),
      {:tick, 0, :keep_turn},
      1_000
    )
  end

  defp start_turn_timer(ref), do: ref

  @spec cancel_tick_timer(nil | reference()) :: nil | reference()
  defp cancel_tick_timer(nil), do: nil
  defp cancel_tick_timer(ref), do: Process.cancel_timer(ref)
end
