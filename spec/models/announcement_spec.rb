describe Announcement do
  describe "default scope" do
    it "should return the newest announcements first" do
      announcement1 = create :announcement
      announcement2 = create :announcement
      expect(Announcement.all).to eq [announcement2, announcement1]
    end
  end

  describe "validations" do
    it "requires a title" do
      announcement = build :announcement, title: ""
      expect(announcement).to_not be_valid
      expect(announcement.errors[:title]).to include "can't be blank"
    end

    it "requires a body" do
      announcement = build :announcement, body: ""
      expect(announcement).to_not be_valid
      expect(announcement.errors[:body]).to include "can't be blank"
    end

    it "requires a course" do
      announcement = build :announcement, course_id: nil
      expect(announcement).to_not be_valid
      expect(announcement.errors[:course]).to include "can't be blank"
    end

    it "requires an author" do
      announcement = build :announcement, author_id: nil
      expect(announcement).to_not be_valid
      expect(announcement.errors[:author]).to include "can't be blank"
    end
  end

  describe "#abstract" do
    let(:body) do <<-BODY
        I am honored to be with you today at your commencement from one of the finest universities in the world. I never graduated from college. Truth be told, this is the closest I've ever gotten to a college graduation. Today I want to tell you three stories from my life. That's it. No big deal. Just three stories.

        The first story is about connecting the dots.

        I dropped out of Reed College after the first 6 months, but then stayed around as a drop-in for another 18 months or so before I really quit. So why did I drop out?
      BODY
    end
    subject { Announcement.new body: body }

    it "returns the first 25 words by default" do
      expect(subject.abstract).to eq "I am honored to be with you today at your commencement from one of the finest universities in the world. I never graduated from college."
    end

    it "returns the specified number of words" do
      expect(subject.abstract(3)).to eq "I am honored"
    end
  end

  describe "#deliver!" do
    let(:course) { create :course }
    let(:delivery) { double(:email, deliver_now: nil) }
    let(:student) { create :user }
    subject { create :announcement, course: course }

    before(:each) do
      create(:course_membership, :student, course_id: course.id, user_id: student.id)
    end

    it "sends an email to all the users in the course" do
      expect(delivery).to receive(:deliver_now)
      expect(AnnouncementMailer).to \
        receive(:announcement_email).with(subject, student).and_return delivery
      subject.deliver!
    end

    it "sends an email only to the recipient if it is set" do
      another_student = create :user
      subject.update_attributes recipient: another_student

      expect(AnnouncementMailer).to \
        receive(:announcement_email).with(subject, another_student).and_return delivery
      expect(AnnouncementMailer).to_not \
        receive(:announcement_email).with(subject, student)

      subject.deliver!
    end
  end

  describe "#read_count" do
    it "is the number of users for the course who have not read the announcement" do
      announcement = create :announcement
      create :announcement_state, announcement: announcement
      expect(announcement.read_count).to eq 1
    end
  end

  describe "#unread_count" do
    it "is the number of students for the course who have not read the announcement" do
      announcement = create :announcement
      create(:course_membership, :student, course_id: announcement.course.id, user_id: announcement.author.id)
      expect(announcement.unread_count).to eq 1
    end

    it "returns zero if there is no course associated with the announcement" do
      announcement = build :announcement, course: nil
      expect(announcement.unread_count).to be_zero
    end

    context "with an announcement for a specific recipient" do
      subject { create :announcement, :for_recipient }

      it "returns 1 if the recipient has not yet read the announcement" do
        expect(subject.unread_count).to eq 1
      end

      it "returns 0 if the recipient has read it" do
        AnnouncementState.create announcement: subject, user: subject.recipient, read: true

        expect(subject.unread_count).to be_zero
      end
    end
  end

  describe ".read_count_for" do
    subject { create :announcement }

    it "returns the number of read announcements for a specific student and course" do
      create(:course_membership, :student, course_id: subject.course.id, user_id: subject.author.id)
      create :announcement_state, announcement: subject, user: subject.author
      expect(Announcement.read_count_for(subject.author, subject.course)).to eq 1
    end

    context "with announcements for a specific recipient" do
      let!(:recipient_announcement) { create :announcement, :for_recipient,
                                      course: subject.course }
      let(:recipient) { recipient_announcement.recipient }

      it "returns the number of read announcements for a specific student and course" do
        create :announcement_state, announcement: subject, user: recipient
        create :announcement_state, announcement: recipient_announcement, user: recipient

        expect(Announcement.read_count_for(recipient, subject.course)).to eq 2
      end
    end
  end

  describe ".unread_count_for" do
    subject { create :announcement }

    it "returns the number of unread announcements for a specific student and course" do
      create(:course_membership, :student, course_id: subject.course.id, user_id: subject.author.id)
      expect(Announcement.unread_count_for(subject.author, subject.course)).to eq 1
    end

    context "with announcements for a specific recipient" do
      let!(:recipient_announcement) { create :announcement, course: subject.course,
                                      recipient: subject.author }

      it "returns the number of unread announcements for a specific student and course" do
        expect(Announcement.unread_count_for(subject.author, subject.course)).to eq 2
      end
    end
  end

  describe "#mark_as_read!" do
    let(:user) { create :user }
    subject { create :announcement }

    it "marks the announcement as read by the specific student" do
      create(:course_membership, :student, course_id: subject.course.id, user_id: user.id)
      subject.mark_as_read! user
      states = AnnouncementState.where(announcement_id: subject.id,
                                               user_id: user.id,
                                                  read: true)
      expect(states.count).to eq 1
    end

    it "marks as read if the user is not a student" do
      create(:course_membership, :professor, course_id: subject.course.id, user_id: user.id)
      subject.mark_as_read! user
      states = AnnouncementState.where(announcement_id: subject.id,
                                               user_id: user.id,
                                                  read: true)
      expect(states.count).to eq 1
    end

    it "does not mark as read if the user is not part of the course" do
      new_course = create :course
      create(:course_membership, :student, course_id: new_course.id, user_id: user.id)
      subject.mark_as_read! user
      expect(subject.states).to be_empty
    end

    it "does not mark as read again if the user already has read it" do
      create(:course_membership, :student, course_id: subject.course.id, user_id: user.id)
      2.times { subject.mark_as_read! user }
      states = AnnouncementState.where(announcement_id: subject.id,
                                               user_id: user.id,
                                                  read: true)
      expect(states.count).to eq 1
    end
  end

  describe "#mark_as_unread!" do
    let(:user) { create :user }
    subject { create :announcement }

    it "marks the announcement as unread by the specific student" do
      create :announcement_state, announcement_id: subject.id, user_id: user.id
      subject.mark_as_unread! user
      expect(subject.states).to be_empty
    end
  end

  describe "#unread?" do
    let(:user) { create :user }
    subject { create :announcement }

    it "returns true if the specified student has not read the announcement" do
      expect(subject.unread?(user)).to be_truthy
    end

    it "returns false if the specified student has read the announcement" do
      create :announcement_state, announcement_id: subject.id, user_id: user.id
      expect(subject.unread?(user)).to be_falsey
    end
  end

  describe "#read?" do
    let(:user) { create :user }
    subject { create :announcement }

    it "returns false if the specified student has not read the announcement" do
      expect(subject.read?(user)).to be_falsey
    end

    it "returns true if the specified student has read the announcement" do
      create :announcement_state, announcement_id: subject.id, user_id: user.id
      expect(subject.read?(user)).to be_truthy
    end
  end
end
