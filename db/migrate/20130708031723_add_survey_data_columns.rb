class AddSurveyDataColumns < ActiveRecord::Migration
  def up
    add_column :states, :survey_not_recommended, :integer
    add_column :states, :survey_probably_recommended, :integer
    add_column :states, :survey_definitely_recommended, :integer
  end

  def down
  end
end
