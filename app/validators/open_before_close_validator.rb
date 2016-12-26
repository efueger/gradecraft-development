class OpenBeforeCloseValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    record.errors.add :base, "Due date must be after open date." if (record.due_at? && record.open_at?) && (record.due_at < record.open_at)
  end
end
