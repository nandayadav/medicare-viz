class CreateDiagnosticRelatedGroups < ActiveRecord::Migration
  def change
    create_table :diagnostic_related_groups do |t|
      t.string    :definition
      t.timestamps
    end
  end
end
