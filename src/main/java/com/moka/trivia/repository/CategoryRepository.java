package com.moka.trivia.repository;

import com.moka.trivia.model.Category;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface CategoryRepository extends JpaRepository<Category, Long> {
}

//@Repository - אומר ל־ספרינג שזו מחלקה שעובדת עם מסד נתונים
//CategoryRepository (interface) - ממשק  לגישה לטבלת הקטגוריות
//extends JpaRepository<Category,Long> - מקבל את כל הפעולות הבסיסיות על מסד נתונים בצורה אוטומטית
//"ספרינג" משלים עבורינו את כל הפעולות מאחורי הקלעים
