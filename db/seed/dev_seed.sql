-- Development seed data: fictitious members, profiles, skills, experiences, projects, links
-- and media. NEVER run in production: this folder is not copied into the Docker image (see
-- db/.dockerignore). Load it with db/seed/seed.sh, which also copies the files of
-- db/seed/media/ into uploads/ (see api/README.md).
--
-- Every member logs in with the password "demo-password".
--
-- Running it again creates no duplicates and keeps the rows changed by hand: tables with a
-- natural key use ON CONFLICT DO NOTHING, the others (experiences and links) WHERE NOT EXISTS.
-- The ids are generated, so the rows are looked up by login, slug or French skill name.
--
-- Edge cases covered:
--   panda     complete profile, the reference case: avatar, French and English CVs, links,
--             phone, availability and "now" section
--   hugo     hidden portfolio, no avatar, no CV, no link, no availability
--   camille   contact form off, two links of the same kind with a label, French CV only
--   mathioux  French CV only
--   projects  draft (ctf-toolkit), ongoing (secure-notes, ended_on NULL), without cover
--             (ctf-toolkit), group project (pixel-quest), pending invitation (hugo on
--             ctf-toolkit), member with a hidden portfolio (hugo on secure-notes)

-- ============================================================
-- Skills
-- ============================================================

-- Technical names only fill "fr": the website falls back to it in English.
INSERT INTO skills (name, category, icon) VALUES
    ('{"fr": "Python"}',                               'language',   'i-simple-icons-python'),
    ('{"fr": "TypeScript"}',                           'language',   'i-simple-icons-typescript'),
    ('{"fr": "SQL"}',                                  'language',   'i-lucide-database'),
    ('{"fr": "Vue.js"}',                               'framework',  'i-simple-icons-vuedotjs'),
    ('{"fr": "Nuxt"}',                                 'framework',  'i-simple-icons-nuxt'),
    ('{"fr": "FastAPI"}',                              'framework',  'i-simple-icons-fastapi'),
    ('{"fr": "Tailwind CSS"}',                         'framework',  'i-simple-icons-tailwindcss'),
    ('{"fr": "PostgreSQL"}',                           'database',   'i-simple-icons-postgresql'),
    ('{"fr": "Docker"}',                               'tool',       'i-simple-icons-docker'),
    ('{"fr": "Git"}',                                  'tool',       'i-simple-icons-git'),
    ('{"fr": "Linux"}',                                'tool',       'i-simple-icons-linux'),
    ('{"fr": "Figma"}',                                'tool',       'i-simple-icons-figma'),
    ('{"fr": "Claude Code"}',                          'ai',         'i-simple-icons-claude'),
    ('{"fr": "Cybersécurité", "en": "Cybersecurity"}', 'domain',     'i-lucide-shield-check'),
    ('{"fr": "Réseaux", "en": "Networking"}',          'domain',     'i-lucide-network'),
    ('{"fr": "Scrum"}',                                'method',     'i-lucide-kanban'),
    ('{"fr": "CI/CD"}',                                'method',     'i-lucide-refresh-cw'),
    ('{"fr": "Design UI/UX", "en": "UI/UX design"}',   'design',     'i-lucide-pen-tool'),
    ('{"fr": "Illustration"}',                         'art',        'i-lucide-brush'),
    ('{"fr": "Photographie", "en": "Photography"}',    'art',        'i-lucide-camera'),
    ('{"fr": "Travail en équipe", "en": "Teamwork"}',  'soft_skill', 'i-lucide-users'),
    -- No icon: the website shows the name alone.
    ('{"fr": "Communication"}',                        'soft_skill', NULL)
ON CONFLICT ((name ->> 'fr')) DO NOTHING;

-- ============================================================
-- Users and profiles
-- ============================================================

INSERT INTO users (login, password_hash)
SELECT login, crypt('demo-password', gen_salt('bf', 12))
FROM (VALUES ('panda'), ('mathioux'), ('camille'), ('hugo')) AS v(login)
ON CONFLICT (login) DO NOTHING;

-- Each row: identity (login, slug and display name differ on purpose, so that they are not
-- mixed up), headline, bio, location and contact, "now", then the dates.
INSERT INTO profiles (idUser, slug, is_public, display_name, headline, bio,
                      location, contact_email, contact_phone, contact_form_enabled, availability,
                      now, now_updated_at, created_at, updated_at)
SELECT u.idUser, v.slug, v.is_public, v.display_name, v.headline::l10n, v.bio::l10n,
       v.location, v.contact_email, v.contact_phone, v.contact_form_enabled, v.availability,
       v.now::l10n, v.now_updated_at::timestamptz, v.created_at::timestamptz, v.updated_at::timestamptz
FROM (VALUES
    ('panda', 'panda-dev', true, 'Panda',
     '{"fr": "Développeur full-stack", "en": "Full-stack developer"}',
     '{"fr": "Développeur **full-stack** fictif, passionné par les interfaces soignées et les API bien rangées.\n\nCe profil sert de données de démonstration.",
       "en": "Fictitious **full-stack** developer, keen on polished interfaces and tidy APIs.\n\nThis profile is demo data."}',
     'Lyon, France', 'panda@example.com', '+33600000001', true, 'open_to_work',
     '{"fr": "J''apprends Rust et je monte un homelab sous Proxmox.",
       "en": "Learning Rust and building a Proxmox homelab."}',
     '2026-11-01 10:00:00+01', '2025-09-01 09:00:00+02', '2026-11-01 10:00:00+01'),

    ('mathioux', 'mathioux-sec', true, 'Mathioux',
     '{"fr": "Développeur back-end et cybersécurité", "en": "Back-end developer and cybersecurity"}',
     '{"fr": "Développeur back-end fictif, curieux de tout ce qui touche à la sécurité : CTF, pentest, durcissement de serveurs.\n\nCe profil sert de données de démonstration.",
       "en": "Fictitious back-end developer, curious about everything security: CTFs, pentesting, server hardening.\n\nThis profile is demo data."}',
     'Grenoble, France', 'mathioux@example.com', NULL, true, 'apprenticeship',
     '{"fr": "Je prépare la certification eJPT.", "en": "Preparing for the eJPT certification."}',
     '2026-10-12 18:30:00+02', '2025-09-01 09:05:00+02', '2026-10-12 18:30:00+02'),

    ('camille', 'camille-rousseau', true, 'Camille Rousseau',
     '{"fr": "Graphiste et illustratrice", "en": "Graphic designer and illustrator"}',
     '{"fr": "Graphiste fictive : identités visuelles, illustrations et pixel art pour le jeu vidéo.",
       "en": "Fictitious graphic designer: visual identities, illustrations and pixel art for video games."}',
     'Bordeaux, France', 'camille@example.com', '+33600000003', false, 'not_available',
     NULL,
     NULL, '2026-02-15 14:00:00+01', '2026-06-20 11:00:00+02'),

    ('hugo', 'hugo-lefevre', false, 'Hugo Lefèvre',
     '{"fr": "Étudiant en BTS SIO", "en": "BTS SIO student"}',
     '{"fr": "Portfolio en cours de rédaction.", "en": "Portfolio in progress."}',
     NULL, NULL, NULL, true, NULL,
     NULL,
     NULL, '2026-09-10 08:00:00+02', '2026-09-10 08:00:00+02')
) AS v(login, slug, is_public, display_name, headline, bio,
       location, contact_email, contact_phone, contact_form_enabled, availability,
       now, now_updated_at, created_at, updated_at)
JOIN users u ON u.login = v.login
ON CONFLICT (idUser) DO NOTHING;

-- ============================================================
-- Media
-- ============================================================

-- Fixed ids: the file of each row is db/seed/media/<idMedia>.webp or .pdf, copied into
-- uploads/ by seed.sh. width, height and size_bytes match the real files.
INSERT INTO media (idMedia, idOwner, storage_key, mime_type, width, height, size_bytes, alt)
SELECT v.idMedia::uuid, u.idUser,
       v.idMedia || CASE v.mime_type WHEN 'application/pdf' THEN '.pdf' ELSE '.webp' END,
       v.mime_type, v.width, v.height, v.size_bytes, v.alt::l10n
FROM (VALUES
    -- Avatars
    ('01a1dd51-e4c5-7220-9fa6-44b2e95ba0b6', 'panda',    'image/webp', 400, 400, 2330,
     '{"fr": "Photo de profil de Panda", "en": "Profile picture of Panda"}'),
    ('01a1dd51-e9b9-75e4-baf0-996b6c472cf4', 'mathioux', 'image/webp', 400, 400, 3100,
     '{"fr": "Photo de profil de Mathioux", "en": "Profile picture of Mathioux"}'),
    ('01a1dd51-e9c6-76b9-bc11-70b2f74416f6', 'camille',  'image/webp', 400, 400, 2492,
     '{"fr": "Photo de profil de Camille Rousseau", "en": "Profile picture of Camille Rousseau"}'),

    -- CVs
    ('01a1dd51-e9d2-7392-908f-3664afa857cb', 'panda',    'application/pdf', NULL, NULL, 14126,
     '{"fr": "CV de Panda", "en": "Resume of Panda (French)"}'),
    ('01a1dd51-e9e0-76bc-aaa1-8b593d1b902d', 'panda',    'application/pdf', NULL, NULL, 14093,
     '{"fr": "CV de Panda (anglais)", "en": "Resume of Panda (English)"}'),
    ('01a1dd51-e9ea-73d4-bbda-63368693a396', 'mathioux', 'application/pdf', NULL, NULL, 14555,
     '{"fr": "CV de Mathioux", "en": "Resume of Mathioux (French)"}'),
    ('01a1dd51-e9f3-77c3-ad6b-122308d56978', 'camille',  'application/pdf', NULL, NULL, 15786,
     '{"fr": "CV de Camille Rousseau", "en": "Resume of Camille Rousseau (French)"}'),

    -- Project covers
    ('01a1dd51-e9fc-7453-9f7b-aef9f78ee867', 'panda',    'image/webp', 1200, 675, 6372,
     '{"fr": "Écran titre du jeu Pixel Quest", "en": "Title screen of the Pixel Quest game"}'),
    ('01a1dd51-ea27-774b-9362-165287bd1939', 'mathioux', 'image/webp', 1200, 675, 6760,
     '{"fr": "Logo de Secure Notes", "en": "Secure Notes logo"}'),
    ('01a1dd51-ea53-71c2-ba4b-7b73f2e189aa', 'panda',    'image/webp', 1200, 675, 9468,
     '{"fr": "Tableau de bord du homelab", "en": "Homelab dashboard"}'),
    ('01a1dd51-ea81-7730-a927-11852ee242f8', 'camille',  'image/webp', 1200, 675, 9100,
     '{"fr": "Couverture du carnet de croquis", "en": "Cover of the sketchbook"}'),

    -- Galleries
    ('01a1dd51-eaad-7045-9747-2bb9609d1b58', 'camille',  'image/webp', 1200, 800, 9032,
     '{"fr": "Pixel Quest : carte du monde", "en": "Pixel Quest: world map"}'),
    ('01a1dd51-eadf-7639-9116-7a1de43a0c8f', 'camille',  'image/webp', 1200, 800, 8840,
     '{"fr": "Pixel Quest : combat contre le boss", "en": "Pixel Quest: boss fight"}'),
    ('01a1dd51-eb5c-725a-875b-c249eca818f8', 'panda',    'image/webp', 1200, 800, 8216,
     '{"fr": "Pixel Quest : inventaire", "en": "Pixel Quest: inventory"}'),
    ('01a1dd51-eb8d-7788-8cdd-09f7b8d0d465', 'panda',    'image/webp', 1200, 800, 11988,
     '{"fr": "Graphiques de charge CPU", "en": "CPU load charts"}'),
    ('01a1dd51-ebc1-7676-b987-1694059684cc', 'panda',    'image/webp', 1200, 800, 12180,
     '{"fr": "Alertes du homelab", "en": "Homelab alerts"}')
) AS v(idMedia, login, mime_type, width, height, size_bytes, alt)
JOIN users u ON u.login = v.login
ON CONFLICT (idMedia) DO NOTHING;

INSERT INTO attaches (idUser, idMedia, kind)
SELECT u.idUser, v.idMedia::uuid, v.kind
FROM (VALUES
    ('panda',    '01a1dd51-e4c5-7220-9fa6-44b2e95ba0b6', 'avatar'),
    ('panda',    '01a1dd51-e9d2-7392-908f-3664afa857cb', 'cv_fr'),
    ('panda',    '01a1dd51-e9e0-76bc-aaa1-8b593d1b902d', 'cv_en'),
    ('mathioux', '01a1dd51-e9b9-75e4-baf0-996b6c472cf4', 'avatar'),
    ('mathioux', '01a1dd51-e9ea-73d4-bbda-63368693a396', 'cv_fr'),
    ('camille',  '01a1dd51-e9c6-76b9-bc11-70b2f74416f6', 'avatar'),
    ('camille',  '01a1dd51-e9f3-77c3-ad6b-122308d56978', 'cv_fr')
) AS v(login, idMedia, kind)
JOIN users u ON u.login = v.login
ON CONFLICT DO NOTHING;

-- ============================================================
-- Social links and skills of the members
-- ============================================================

-- Fictitious accounts on real domains: the URLs must match the patterns of link_kinds.
INSERT INTO social_links (idUser, kind, url, label, position)
SELECT u.idUser, v.kind, v.url, v.label, v.position
FROM (VALUES
    ('panda',    'github',     'https://github.com/tkf-demo-panda',                NULL,                0),
    ('panda',    'linkedin',   'https://www.linkedin.com/in/tkf-demo-panda',       NULL,                1),
    ('panda',    'website',    'https://example.com/panda',                        'Blog',              2),
    ('mathioux', 'github',     'https://github.com/tkf-demo-mathioux',             NULL,                0),
    ('mathioux', 'tryhackme',  'https://tryhackme.com/p/tkf-demo-mathioux',        NULL,                1),
    ('mathioux', 'discord',    'https://discord.gg/tkfdemo',                       NULL,                2),
    ('camille',  'artstation', 'https://www.artstation.com/tkf-demo-camille',      NULL,                0),
    ('camille',  'instagram',  'https://www.instagram.com/tkf.demo.camille',       NULL,                1),
    ('camille',  'youtube',    'https://www.youtube.com/@tkf-demo-camille',        'Chaîne principale', 2),
    ('camille',  'youtube',    'https://www.youtube.com/@tkf-demo-camille-shorts', 'Speed paintings',   3),
    ('camille',  'kofi',       'https://ko-fi.com/tkfdemocamille',                 NULL,                4)
) AS v(login, kind, url, label, position)
JOIN users u ON u.login = v.login
WHERE NOT EXISTS (SELECT FROM social_links s WHERE s.idUser = u.idUser AND s.url = v.url);

INSERT INTO masters (idUser, idSkill, score, position)
SELECT u.idUser, s.idSkill, v.score, v.position
FROM (VALUES
    ('panda',    'TypeScript',        85, 0),
    ('panda',    'Nuxt',              80, 1),
    ('panda',    'Python',            70, 2),
    ('panda',    'PostgreSQL',        60, 3),
    ('panda',    'Docker',            55, 4),
    ('panda',    'Claude Code',       75, 5),
    ('panda',    'Travail en équipe', 90, 6),
    ('mathioux', 'Python',            85, 0),
    ('mathioux', 'FastAPI',           75, 1),
    ('mathioux', 'SQL',               70, 2),
    ('mathioux', 'Cybersécurité',     60, 3),
    ('mathioux', 'Linux',             65, 4),
    ('mathioux', 'Réseaux',           40, 5),
    ('camille',  'Illustration',      95, 0),
    ('camille',  'Design UI/UX',      70, 1),
    ('camille',  'Figma',             80, 2),
    ('camille',  'Photographie',      45, 3),
    ('camille',  'Communication',     85, 4),
    ('hugo',     'Python',            20, 0),
    ('hugo',     'SQL',               15, 1)
) AS v(login, skill, score, position)
JOIN users u ON u.login = v.login
JOIN skills s ON s.name ->> 'fr' = v.skill
ON CONFLICT DO NOTHING;

-- ============================================================
-- Experiences
-- ============================================================

-- An experience is identified by its member, organization and start date.
-- Each row: kind and organization, title, status and contract, description, place and dates.
INSERT INTO experiences (idUser, kind, organization, title, employment_status, contract_type,
                         description, location, start_on, end_on)
SELECT u.idUser, v.kind, v.organization, v.title::l10n, v.employment_status, v.contract_type,
       v.description::l10n, v.location, v.start_on::date, v.end_on::date
FROM (VALUES
    ('panda', 'work', 'Studio Bambou',
     '{"fr": "Développeur front-end", "en": "Front-end developer"}',
     'employee', 'apprenticeship',
     '{"fr": "Refonte du site vitrine en Nuxt, création d''une bibliothèque de composants.",
       "en": "Rebuilt the showcase website with Nuxt, created a component library."}',
     'Lyon', '2024-09-02', '2026-08-31'),

    ('panda', 'education', 'Lycée Lumière',
     '{"fr": "BTS SIO option SLAM", "en": "BTS SIO, software development option"}',
     NULL, NULL,
     '{"fr": "Développement d''applications, bases de données et gestion de projet.",
       "en": "Application development, databases and project management."}',
     'Lyon', '2024-09-02', '2026-07-03'),

    ('panda', 'training', 'TryHackMe',
     '{"fr": "Parcours Pre Security", "en": "Pre Security path"}',
     NULL, NULL,
     '{"fr": "Bases des réseaux, du web et de Linux.", "en": "Networking, web and Linux basics."}',
     NULL, '2025-03-01', '2025-05-15'),

    ('mathioux', 'work', 'CyberNord',
     '{"fr": "Alternant développeur back-end", "en": "Back-end developer apprentice"}',
     'employee', 'apprenticeship',
     '{"fr": "Développement d''API FastAPI et audit des dépendances.",
       "en": "Built FastAPI APIs and audited dependencies."}',
     'Grenoble', '2025-09-01', NULL),

    ('mathioux', 'work', 'Mairie de Saint-Exemple',
     '{"fr": "Stagiaire administrateur systèmes", "en": "Systems administrator intern"}',
     NULL, 'internship',
     '{"fr": "Migration du parc vers Debian, sauvegardes automatisées.",
       "en": "Migrated the machines to Debian, automated the backups."}',
     'Saint-Exemple', '2025-05-12', '2025-06-27'),

    ('mathioux', 'training', 'ANSSI',
     '{"fr": "MOOC SecNumacadémie", "en": "SecNumacadémie MOOC"}',
     NULL, NULL,
     '{"fr": "Sensibilisation à la sécurité numérique.", "en": "Digital security awareness."}',
     NULL, '2025-01-06', '2025-02-14'),

    ('camille', 'work', 'Indépendante',
     '{"fr": "Illustratrice freelance", "en": "Freelance illustrator"}',
     NULL, 'freelance',
     '{"fr": "Illustrations et pixel art pour des studios de jeu indépendants.",
       "en": "Illustrations and pixel art for indie game studios."}',
     'Bordeaux', '2023-01-01', NULL),

    ('camille', 'education', 'École Exemple d''Arts Appliqués',
     '{"fr": "DN MADE graphisme", "en": "DN MADE in graphic design"}',
     NULL, NULL,
     '{"fr": "Identité visuelle, typographie et illustration.",
       "en": "Visual identity, typography and illustration."}',
     'Bordeaux', '2019-09-02', '2022-06-30')
) AS v(login, kind, organization, title, employment_status, contract_type,
       description, location, start_on, end_on)
JOIN users u ON u.login = v.login
WHERE NOT EXISTS (
    SELECT FROM experiences e
    WHERE e.idUser = u.idUser AND e.organization = v.organization AND e.start_on = v.start_on::date
);

INSERT INTO experience_links (idExperience, kind, url, label, position)
SELECT e.idExperience, v.kind, v.url, v.label, v.position
FROM (VALUES
    ('panda',    'Studio Bambou', '2024-09-02', 'website',
     'https://example.com/studio-bambou',                    NULL,                0),
    ('panda',    'TryHackMe',     '2025-03-01', 'tryhackme',
     'https://tryhackme.com/path/outline/presecurity',       NULL,                0),
    ('panda',    'TryHackMe',     '2025-03-01', 'certificate',
     'https://example.com/certificates/presecurity',         'Certificat',        1),
    ('mathioux', 'CyberNord',     '2025-09-01', 'website',
     'https://example.com/cybernord',                        NULL,                0),
    ('mathioux', 'CyberNord',     '2025-09-01', 'linkedin',
     'https://www.linkedin.com/company/tkf-demo-cybernord',  NULL,                1),
    ('mathioux', 'ANSSI',         '2025-01-06', 'certificate',
     'https://example.com/certificates/secnumacademie',      'Attestation',       0),
    ('camille',  'Indépendante',  '2023-01-01', 'youtube',
     'https://www.youtube.com/@tkf-demo-camille',            'Chaîne principale', 0)
) AS v(login, organization, start_on, kind, url, label, position)
JOIN users u ON u.login = v.login
JOIN experiences e
    ON e.idUser = u.idUser AND e.organization = v.organization AND e.start_on = v.start_on::date
WHERE NOT EXISTS (SELECT FROM experience_links l WHERE l.idExperience = e.idExperience AND l.url = v.url);

INSERT INTO involves (idExperience, idSkill)
SELECT e.idExperience, s.idSkill
FROM (VALUES
    ('panda',    'Studio Bambou',                   '2024-09-02', 'Nuxt'),
    ('panda',    'Studio Bambou',                   '2024-09-02', 'TypeScript'),
    ('panda',    'Studio Bambou',                   '2024-09-02', 'Tailwind CSS'),
    ('panda',    'Lycée Lumière',                   '2024-09-02', 'SQL'),
    ('panda',    'Lycée Lumière',                   '2024-09-02', 'Scrum'),
    ('panda',    'TryHackMe',                       '2025-03-01', 'Réseaux'),
    ('mathioux', 'CyberNord',                       '2025-09-01', 'FastAPI'),
    ('mathioux', 'CyberNord',                       '2025-09-01', 'CI/CD'),
    ('mathioux', 'Mairie de Saint-Exemple',         '2025-05-12', 'Linux'),
    ('mathioux', 'ANSSI',                           '2025-01-06', 'Cybersécurité'),
    ('camille',  'Indépendante',                    '2023-01-01', 'Illustration'),
    ('camille',  'École Exemple d''Arts Appliqués', '2019-09-02', 'Design UI/UX')
) AS v(login, organization, start_on, skill)
JOIN users u ON u.login = v.login
JOIN experiences e
    ON e.idUser = u.idUser AND e.organization = v.organization AND e.start_on = v.start_on::date
JOIN skills s ON s.name ->> 'fr' = v.skill
ON CONFLICT DO NOTHING;

-- ============================================================
-- Projects
-- ============================================================

-- Each new project gets its accepted members below, in the same transaction: the deferred
-- trigger of 03_triggers.sql checks them at COMMIT. seed.sh runs this file in one transaction.
-- Each row: slug, title, summary, content, cover and URLs, dates, flags and position.
INSERT INTO projects (slug, title, summary, content, idCover, repo_url, demo_url,
                      started_on, ended_on, is_published, is_featured, position, updated_at)
SELECT v.slug, v.title::l10n, v.summary::l10n, v.content::l10n,
       v.idCover::uuid, v.repo_url, v.demo_url,
       v.started_on::date, v.ended_on::date, v.is_published, v.is_featured, v.position,
       v.updated_at::timestamptz
FROM (VALUES
    ('pixel-quest',
     '{"fr": "Pixel Quest"}',
     '{"fr": "Petit jeu d''aventure en pixel art jouable dans le navigateur.",
       "en": "Small pixel art adventure game playable in the browser."}',
     '{"fr": "## Le jeu\n\nUn héros, trois donjons et un boss final.\n\n## Technique\n\n- Rendu sur `<canvas>` en TypeScript\n- Sauvegarde dans le navigateur",
       "en": "## The game\n\nOne hero, three dungeons and a final boss.\n\n## Tech\n\n- `<canvas>` rendering in TypeScript\n- Saved in the browser"}',
     '01a1dd51-e9fc-7453-9f7b-aef9f78ee867',
     'https://github.com/tkf-demo-panda/pixel-quest', 'https://example.com/pixel-quest',
     '2025-10-01', '2026-03-15', true, true, 0, '2026-03-15 20:00:00+01'),

    ('secure-notes',
     '{"fr": "Secure Notes"}',
     '{"fr": "API de prise de notes chiffrées de bout en bout.",
       "en": "End-to-end encrypted note-taking API."}',
     '{"fr": "API FastAPI qui ne stocke que des notes chiffrées côté client.\n\nProjet en cours.",
       "en": "FastAPI API that only stores notes encrypted on the client side.\n\nOngoing project."}',
     '01a1dd51-ea27-774b-9362-165287bd1939',
     'https://github.com/tkf-demo-mathioux/secure-notes', NULL,
     '2026-04-01', NULL, true, true, 1, '2026-11-02 17:45:00+01'),

    ('homelab-monitoring',
     '{"fr": "Supervision du homelab", "en": "Homelab monitoring"}',
     '{"fr": "Tableau de bord qui surveille les serveurs de la maison.",
       "en": "Dashboard that monitors the home servers."}',
     '{"fr": "Collecte des métriques, alertes par e-mail et graphiques en temps réel.",
       "en": "Metrics collection, email alerts and live charts."}',
     '01a1dd51-ea53-71c2-ba4b-7b73f2e189aa',
     'https://github.com/tkf-demo-panda/homelab-monitoring', NULL,
     '2025-01-10', '2025-06-30', true, false, 2, '2025-06-30 12:00:00+02'),

    ('carnet-de-croquis',
     '{"fr": "Carnet de croquis", "en": "Sketchbook"}',
     '{"fr": "Une illustration par jour pendant un an.", "en": "One illustration a day for a year."}',
     NULL,
     '01a1dd51-ea81-7730-a927-11852ee242f8',
     NULL, NULL,
     '2024-01-01', '2024-12-31', true, false, 3, '2025-01-05 10:00:00+01'),

    ('ctf-toolkit',
     '{"fr": "Boîte à outils CTF", "en": "CTF toolkit"}',
     '{"fr": "Scripts pour automatiser les étapes répétitives des CTF.",
       "en": "Scripts that automate the repetitive steps of CTFs."}',
     NULL,
     NULL,
     NULL, NULL,
     '2026-10-01', NULL, false, false, 4, '2026-11-10 22:00:00+01')
) AS v(slug, title, summary, content, idCover, repo_url, demo_url,
       started_on, ended_on, is_published, is_featured, position, updated_at)
ON CONFLICT (slug) DO NOTHING;

INSERT INTO works_on (idProject, idUser, status, role)
SELECT p.idProject, u.idUser, v.status, v.role::l10n
FROM (VALUES
    ('pixel-quest',        'panda',    'accepted',
     '{"fr": "Développement, game design", "en": "Development, game design"}'),
    ('pixel-quest',        'camille',  'accepted',
     '{"fr": "Graphismes, animations", "en": "Art, animations"}'),
    ('pixel-quest',        'mathioux', 'accepted', NULL),
    ('secure-notes',       'mathioux', 'accepted',
     '{"fr": "API, chiffrement", "en": "API, encryption"}'),
    ('secure-notes',       'hugo',     'accepted',
     '{"fr": "Tests", "en": "Testing"}'),
    ('homelab-monitoring', 'panda',    'accepted', NULL),
    ('carnet-de-croquis',  'camille',  'accepted', NULL),
    ('ctf-toolkit',        'mathioux', 'accepted', NULL),
    -- Invitation not answered yet: not shown on the project page.
    ('ctf-toolkit',        'hugo',     'pending',  NULL)
) AS v(slug, login, status, role)
JOIN projects p ON p.slug = v.slug
JOIN users u ON u.login = v.login
ON CONFLICT DO NOTHING;

INSERT INTO uses (idProject, idSkill)
SELECT p.idProject, s.idSkill
FROM (VALUES
    ('pixel-quest',        'TypeScript'),
    ('pixel-quest',        'Illustration'),
    ('pixel-quest',        'Git'),
    ('secure-notes',       'Python'),
    ('secure-notes',       'FastAPI'),
    ('secure-notes',       'PostgreSQL'),
    ('secure-notes',       'Cybersécurité'),
    ('homelab-monitoring', 'Docker'),
    ('homelab-monitoring', 'Linux'),
    ('homelab-monitoring', 'Vue.js'),
    ('carnet-de-croquis',  'Illustration'),
    ('ctf-toolkit',        'Python')
) AS v(slug, skill)
JOIN projects p ON p.slug = v.slug
JOIN skills s ON s.name ->> 'fr' = v.skill
ON CONFLICT DO NOTHING;

INSERT INTO shows (idProject, idMedia, position)
SELECT p.idProject, v.idMedia::uuid, v.position
FROM (VALUES
    ('pixel-quest',        '01a1dd51-eaad-7045-9747-2bb9609d1b58', 0),
    ('pixel-quest',        '01a1dd51-eadf-7639-9116-7a1de43a0c8f', 1),
    ('pixel-quest',        '01a1dd51-eb5c-725a-875b-c249eca818f8', 2),
    ('homelab-monitoring', '01a1dd51-eb8d-7788-8cdd-09f7b8d0d465', 0),
    ('homelab-monitoring', '01a1dd51-ebc1-7676-b987-1694059684cc', 1)
) AS v(slug, idMedia, position)
JOIN projects p ON p.slug = v.slug
ON CONFLICT DO NOTHING;
