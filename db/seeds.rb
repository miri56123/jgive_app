puts "Seeding campaigns..."

campaign1 = Campaign.find_or_create_by!(title: "הגן הכתום") do |c|
  c.subtitle = "לזכר בני משפחת ביבס וילדי ה-7 באוקטובר"
  c.organization_name = "עמותת וְנָטַעְתָּ"
  c.goal_amount = 2_000_000
  c.bonus_goal_amount = 5_000_000
  c.status = :active
  c.cover_image_url = "https://www.jgive.com/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBN1EwQ0E9PSIsImV4cCI6bnVsbCwicHVyIjoiYmxvYl9pZCJ9fQ==--d4cfa52df74f75074286531bb9fd3013907d776b/%D7%94%D7%92%D7%9F%20%D7%94%D7%9B%D7%AA%D7%95%D7%9D%20(2560%20x%201440%20%D7%A4%D7%99%D7%A7%D7%A1%D7%9C)%20(5).jpg"
  c.description = <<~HTML
    <h2>הצטרפו עכשיו והיו ממקימי הגן הכתום</h2>
    <h3>לזכר שירי, אריאל וכפיר ביבס, ולזכר כל ילדי ה-7 באוקטובר.</h3>
    <p>אחרי שנתיים וחצי של כאב, טלטלה והתמודדות, מגיע מיזם שמביא בשורה חדשה לישראל — <strong>מקום של חיים, ריפוי ותקווה.</strong></p>
    <p>אנחנו יוצאים לדרך עם הקמת <strong>הגן הכתום</strong> — מרחב ראשון מסוגו בישראל שמחבר זיכרון, טבע, ילדים וריפוי.</p>
    <p>על פני <strong>20 דונם</strong> יוקם מרחב חי של טבע, מים, משחק, משפחה וריפוי — פתוח לכולם.</p>
    <h3>מה יחכה לנו בגן הכתום?</h3>
    <ul>
      <li><strong>מתחם גינון טיפולי-קהילתי</strong> — מרחב ריפוי דרך הטבע עבור הלומי קרב, בני הגיל השלישי ונוער בסיכון</li>
      <li><strong>בוסתני פרי ומטעים</strong> — הליכה בין עצי פרי, בהשראת הפירות ששירי ואריאל אהבו</li>
      <li><strong>הנחל האקולוגי</strong> — נחל זורם עם גשרי עץ קטנים ומים חיים</li>
      <li><strong>מרחב זיכרון</strong> — פינה מכבדת לזכר ילדי השבעה באוקטובר</li>
      <li><strong>האומגה הכתומה ומתקני משחק</strong> — כי צחוק של ילדים הוא התשובה הכי חזקה לכאב</li>
      <li><strong>קיר המשאלות</strong> — מקום שבו כל ילד וילדה יוכלו להשאיר משאלה, תפילה, תקווה או חלום</li>
      <li><strong>אמפיתיאטרון וכיתות חוץ</strong> — מקום להופעות, פעילות חינוכית וקהילתית</li>
    </ul>
    <p>הפרויקט הוא יוזמה של עמותת ונטעת, בשיתוף משפחת ביבס ועיריית מגדל העמק.</p>
  HTML
end

campaign1.update!(
  title_en: "The Orange Garden",
  subtitle_en: "In memory of the Bibas family and the children of October 7th",
  organization_name_en: "Venata'ta Association",
  description_en: <<~HTML
    <h2>Join now and become one of the founders of the Orange Garden</h2>
    <h3>In memory of Shiri, Ariel and Kfir Bibas, and all the children of October 7th.</h3>
    <p>After two and a half years of pain, upheaval and struggle, comes a project that brings new hope to Israel — <strong>a place of life, healing and hope.</strong></p>
    <p>We are setting out to build <strong>the Orange Garden</strong> — the first space of its kind in Israel, connecting memory, nature, children and healing.</p>
    <p>Across <strong>20 dunams</strong>, a living space of nature, water, play, family and healing will rise — open to all.</p>
    <h3>What awaits us in the Orange Garden?</h3>
    <ul>
      <li><strong>Therapeutic-community gardening area</strong> — a space for healing through nature for combat veterans, seniors and at-risk youth</li>
      <li><strong>Orchards and fruit groves</strong> — a walk among fruit trees, inspired by the fruits Shiri and Ariel loved</li>
      <li><strong>The ecological stream</strong> — a flowing stream with small wooden bridges and living water</li>
      <li><strong>Memorial space</strong> — a respectful corner in memory of the children of October 7th</li>
      <li><strong>The orange zip-line and play facilities</strong> — because children's laughter is the strongest answer to pain</li>
      <li><strong>The wishing wall</strong> — a place where every child can leave a wish, prayer, hope or dream</li>
      <li><strong>Amphitheater and outdoor classrooms</strong> — a place for performances, educational and community activities</li>
    </ul>
    <p>The project is an initiative of the Venata'ta Association, in partnership with the Bibas family and the Migdal HaEmek municipality.</p>
  HTML
)

campaign2 = Campaign.find_or_create_by!(title: "מזון לכל") do |c|
  c.subtitle = "מאבק ברעב ובעוני בישראל"
  c.organization_name = "עמותת לחם לכל"
  c.goal_amount = 500_000
  c.status = :active
  c.cover_image_url = "https://images.unsplash.com/photo-1488521787991-ed7bbaae773c?w=1200&h=675&auto=format&fit=crop"
  c.description = <<~HTML
    <h2>מזון לכל — לא עוד ילד ישן רעב</h2>
    <p>כ-400,000 ילדים בישראל חיים בעוני ומחוסרי מזון. עמותת לחם לכל פועלת כבר 15 שנה לחלוקת סלי מזון, ארוחות חמות ותמיכה לאלפי משפחות מדי שבוע.</p>
    <p><strong>התרומה שלכם תעזור לממן:</strong></p>
    <ul>
      <li>סלי מזון שבועיים ל-500 משפחות</li>
      <li>ארוחות חמות יומיות ל-200 ילדים</li>
      <li>מלגות לרכישת ציוד לבית הספר</li>
    </ul>
    <p>כל שקל חשוב. כל תרומה מצילה.</p>
  HTML
end

campaign2.update!(
  title_en: "Food for All",
  subtitle_en: "Fighting hunger and poverty in Israel",
  organization_name_en: "Bread for All Association",
  description_en: <<~HTML
    <h2>Food for All — no more children going to sleep hungry</h2>
    <p>About 400,000 children in Israel live in poverty and food insecurity. The Bread for All Association has been working for 15 years distributing food baskets, hot meals and support to thousands of families every week.</p>
    <p><strong>Your donation will help fund:</strong></p>
    <ul>
      <li>Weekly food baskets for 500 families</li>
      <li>Daily hot meals for 200 children</li>
      <li>Grants to buy school supplies</li>
    </ul>
    <p>Every shekel matters. Every donation saves.</p>
  HTML
)

puts "Seeded #{Campaign.count} campaigns"

puts "Seeding donations..."

donors = [
  { name: "ישראל כהן",      dedication: "לזכר שירי ז\"ל" },
  { name: "מיכל לוי",       dedication: nil },
  { name: "דוד ברגר",       dedication: "לרפואת כל פצועי ישראל" },
  { name: "רחל גולדמן",     dedication: nil },
  { name: "עמי שפירא",      dedication: "לזכר כל ילדי ה-7 באוקטובר" },
  { name: "נועה רוזנברג",   dedication: nil },
  { name: "ארי פינקל",      dedication: "לזכר אריאל וכפיר ז\"ל" },
  { name: "שרה אברמוביץ",   dedication: nil },
  { name: "יוסי מזרחי",     dedication: "בשם משפחת מזרחי" },
  { name: "לילך בן-דוד",    dedication: nil }
]

amounts = [ 180, 260, 360, 500, 1_000, 1_800, 90, 120, 300 ]
display_prefs = %i[full_name first_name_only anonymous]

Donation.delete_all

10.times do |i|
  donor = donors[i]
  recurring = i.odd?
  Donation.create!(
    campaign: campaign1,
    donor_name: donor[:name],
    amount: amounts[i % amounts.length],
    status: i < 8 ? :paid : :pending,
    frequency: recurring ? :recurring : :one_time,
    months: recurring ? [ 6, 12, 24, 36 ][i / 2 % 4] : nil,
    display_preference: display_prefs[i % 3],
    dedication_message: donor[:dedication]
  )
end

6.times do |i|
  donor = donors[(i + 3) % donors.length]
  Donation.create!(
    campaign: campaign2,
    donor_name: donor[:name],
    amount: amounts[(i + 2) % amounts.length],
    status: i < 4 ? :paid : :pending,
    frequency: :one_time,
    display_preference: i.even? ? :full_name : :first_name_only,
    dedication_message: donor[:dedication]
  )
end

Donation.create!(
  campaign: campaign1,
  donor_name: "קרן משפחת לוינשטיין",
  amount: 800_000,
  status: :paid,
  frequency: :one_time,
  display_preference: :full_name,
  dedication_message: "לזכר ילדי ה-7 באוקטובר"
)

puts "Seeded #{Donation.count} donations"
puts "Done!"
