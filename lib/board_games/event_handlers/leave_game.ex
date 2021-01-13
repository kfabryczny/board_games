defmodule BoardGames.EventHandlers.LeaveGame do
  @moduledoc """
  Logic concerned with updating game state in
  responses to a player leaving.
  """

  alias BoardGames.GameState

  @spec handle({String.t()}, GameState.game_state()) :: {:ok, GameState.game_state()}
  def handle({player_name}, state) do
    if state.status == :setup do
      remaining_players = Enum.reject(state.players, &(&1 == player_name))

      new_state = %{
        state
        | board: Sternhalma.empty_board(),
          marbles: [],
          players: [],
          marble_colors: %{}
      }

      final_state =
        remaining_players
        |> Enum.reduce(new_state, fn player_name, state_acc ->
          {:ok, new_state} = BoardGames.EventHandlers.JoinGame.handle({player_name}, state_acc)
          new_state
        end)

      {:ok, final_state}
    else
      {:ok, state}
    end
  end
end
