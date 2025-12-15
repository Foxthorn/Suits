using Godot;

public partial class SampleManager : Node
{
    private int score;  // No initialization

    public override void _Ready()
    {
        GD.Print("Manager ready");
        // Potential null if no child
        var label = GetNode<Label>("ScoreLabel");
        label.Text = "Score: " + score;
    }

    public void AddPoints(int points)
    {
        score += points;
        // Forgot to update UI!
        
        // Inefficient: String concat in potential hot path
        GD.Print("New score is " + score.ToString() + " points gained: " + points);
    }

    // Unused method
    private void ResetGame()
    {
        score = 0;
    }

    // Missing null check
    public void SaveGame(Node player)
    {
        player.QueueFree();  // Dangerous if player is null
    }
}