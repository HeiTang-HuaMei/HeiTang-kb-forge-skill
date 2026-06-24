# Task Mode Router Basic Resume Prompt

Resume from current_gate=P1-15 Plan-and-Execute Runtime Basic if interrupted before commit.
After commit, resume from next_gate=P1-15 Plan-and-Execute Runtime Basic.
Keep global_goal_complete=false while remaining gates exist.
Do not execute P1-15 until P1-14 evidence is committed.
