package fr.chk.piratewarrior;

import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Spécifications non destructives des nouvelles animations et techniques V5.5.
 * Chaque entrée correspond exclusivement à un personnage déjà présent dans les catalogues du jeu.
 */
public final class CharacterEnhancementCatalog {
    public static final class Spec {
        public final String id;
        public final String displayName;
        public final List<String> animations;
        public final List<String> powers;

        private Spec(String id, String displayName, List<String> animations, List<String> powers) {
            this.id = id;
            this.displayName = displayName;
            this.animations = Collections.unmodifiableList(new ArrayList<>(animations));
            this.powers = Collections.unmodifiableList(new ArrayList<>(powers));
            if (this.animations.size() != 7) throw new IllegalArgumentException(id + " doit avoir 7 animations");
            if (this.powers.size() != 2) throw new IllegalArgumentException(id + " doit avoir 2 pouvoirs");
        }
    }

    private static final Map<String, Spec> SPECS = build();

    private CharacterEnhancementCatalog() {}

    public static Spec byId(String id) { return SPECS.get(id); }
    public static List<Spec> all() { return List.copyOf(SPECS.values()); }

    private static Map<String, Spec> build() {
        LinkedHashMap<String, Spec> result = new LinkedHashMap<>();
        add(result, "cheikh", "Cheikh",
                List.of("marche_capitaine", "sprint_offensif", "saut_assaut", "reception_combat", "parade_royale", "interaction_chef", "victoire_capitaine"),
                List.of("Aura Royale", "Lame d'Éclipse"));
        add(result, "yvane", "Yvane",
                List.of("marche_exploration", "course_rapide", "double_saut", "esquive_roulee", "blocage", "encouragement_allies", "danse_victoire"),
                List.of("Rafale Stellaire", "Bouclier Sacré"));
        add(result, "nelvyn", "Nelvyn",
                List.of("marche_attentive", "course_eclair", "saut_dynamique", "accroupissement", "parade_rapide", "observation", "victoire_energique"),
                List.of("Tornade Éclair", "Hyper Vitesse"));

        for (Enemy25DCatalog.Entry enemy : Enemy25DCatalog.all()) {
            List<String> animations;
            List<String> powers;
            switch (enemy.rank) {
                case BOSS -> {
                    animations = List.of("marche_lourde", "charge", "intimidation", "attaque_signature", "parade", "transformation", "execution");
                    powers = bossPowers(enemy);
                }
                case COMMANDER -> {
                    animations = List.of("marche_tactique", "course", "parade", "esquive", "cri_guerre", "execution_speciale", "victoire");
                    powers = List.of(
                            "Art de " + enemy.weapon + " — " + enemy.displayName,
                            "Assaut combiné avec " + Enemy25DCatalog.bossForIsland(enemy.islandIndex).displayName
                    );
                }
                case SUBORDINATE -> {
                    animations = List.of("marche", "course", "patrouille", "attente", "esquive", "interaction", "victoire");
                    powers = List.of(
                            "Soutien tactique de " + enemy.displayName,
                            "Offensive spéciale — " + enemy.weapon
                    );
                }
                default -> throw new IllegalStateException("Rang inconnu");
            }
            add(result, enemy.id, enemy.displayName, animations, powers);
        }
        return Collections.unmodifiableMap(result);
    }

    private static List<String> bossPowers(Enemy25DCatalog.Entry enemy) {
        return switch (enemy.id) {
            case "brakor" -> List.of("Armure du Gardien", "Raz-de-Marée d'Ancre");
            case "malkor" -> List.of("Forme Dragon-Serpent de la Jungle", "Domaine des Racines Venimeuses");
            case "skarn" -> List.of("Forme Titan Polaire", "Tempête du Zéro Absolu");
            case "zarok" -> List.of("Forme Sphinx des Dunes", "Mer de Sable Royale");
            case "vulkar" -> List.of("Forme Dragon Magmatique", "Éruption du Souverain");
            case "tempyr" -> List.of("Forme Seigneur de l'Orage", "Jugement des Cieux");
            case "matriarche_sucree" -> List.of("Forme Impératrice Chimère", "Royaume Sucré Dévorant");
            case "kaor_crane" -> List.of("Forme Dragon du Crâne", "Souffle Pourpre du Cataclysme");
            default -> List.of(
                    "Forme souveraine de " + enemy.displayName,
                    "Ultime de zone — " + enemy.weapon
            );
        };
    }

    private static void add(Map<String, Spec> target, String id, String name,
                            List<String> animations, List<String> powers) {
        if (target.put(id, new Spec(id, name, animations, powers)) != null) {
            throw new IllegalStateException("Personnage dupliqué : " + id);
        }
    }
}
